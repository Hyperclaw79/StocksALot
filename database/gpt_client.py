"""
This module contains the GptClient client which will interact with the ChatGPT API.
"""
from __future__ import annotations
from enum import Enum
import json
import os
import re
import openai

from utils import logger_factory
from models import Message, GptRoles, InsightsResponse, InsightsRequestsBatch, Insights

MODEL = os.getenv("GPT_MODEL", "gpt-4")
logger = logger_factory(__name__)


EXAMPLE_OUTPUT = """
```json
    {
        "count": 2,
        "items": [
            {
                "datetime": "2023-08-18T15:30:00",
                "insights": [
                    {
                        "message": "Apple starts bullish with a whopping volume of 6,239,136.",
                        "sentiment": "positive"
                    },
                    {
                        "message": "Microsoft is playing it safe with consistent prices.",
                        "sentiment": "neutral"
                    },
                    {
                        "message": "Things are not looking good for Meta with Low prices as low as 282.7.",
                        "sentiment": "negative"
                    }
                ]
            },
            {
                "datetime": "2023-08-18T16:30:00",
                "insights": [
                    {
                        "message": "Tesla's price plummeted to an unexpected low of 214.67.",
                        "sentiment": "negative"
                    },
                    {
                        "message": "Woah! Meta turned the tables with an unexpected high of 550.69.",
                        "sentiment": "positive"
                    },
                    {
                        "message": "Amazon is playing the safe game now with low price fluctuations.",
                        "sentiment": "neutral"
                    }
                ]
            }
        ]
    }
```"""


class Prompts(Enum):
    """A class representing different prompt statements."""
    _RULE = """
        Rank the insights according to this key: (steepness of the change, impact on market).
        Provide the top 3 to 5 insights quoting any relevant figures when required
        (should be accurate to the data).
        Return a json list containing the message and the sentiment of the insight for every insight.
        Use the datetime as the key for the insights.
        Not sending it in the requested format is absolutely unacceptable.
        """
    SINGLE_PROMPT = f"""
        Generate insights based on this OHLC stock data.
        {_RULE}
        """
    MULTI_PROMPT_START = """
        Analyse this OHLC stock data and remember the different values.
        """
    MULTI_PROMPT_END = f"""
        Remember the previous values? Now compare the changes in the following data.
        Generate the insights based on the changes. Observe any peculiar trends.
        {_RULE}
        Example output:
        {EXAMPLE_OUTPUT}
        """


class GptClient:  # pylint: disable=too-few-public-methods
    """
    A client for interacting with the OpenAI GPT API.
    """

    def __init__(self, api_key: str, model: str = MODEL):
        openai.api_key = api_key
        self.model = model
        self.insights_pattern = re.compile(
            r'\d+\.\s(.*?)(?:\((positive|neutral|negative) sentiment\))',
            flags=re.IGNORECASE
        )
        self.behavior_instruction = """
        You are a stock market expert, capable of quickly analysing trends and outliers in stock data.
        You are given a list of stock data and you need to provide a minimum of 3 and a maximum of 5 insights per datetime.

        Some rules for generating the insights:
        1. Insights should not be too complicated. They should make sense to even
        a 10th grade kid who just knows what "stocks" are.
        2. They should be ranked according to this key: (steepness of the change, impact on market).
        3. For each insight, you should also provide a sentiment (positive, negative, neutral).
        4. If the data contains more than one datetime, you should provide insights for each datetime.
        5. For the above case, an insight specifying the trend or shift in trend would be a good idea.
        6. Do not try to guess trends if a single datetime is provided. Just provide insights for that datetime.
        7. Keep the insights unique. Do not repeat the same insight for different stocks.
        8. Be more creative with the insights. Do not just provide the obvious insights.
        9. Sound as human as possible. Do not sound like a robot reporting the data.
        10. Try to get a mix of positive, neutral and negative insights if possible.
        11. **IMPORTANT** - Any figures you quoute should exactly match the figures in the data.
        12. **IMPORTANT** - Do no create a new record for an existing datetime. The number of records should exactly
        match the number of unique datetimes in the data. The insights per datetime should be between 3 and 5.
        13. Sending no insights for a datetime is absolutely unacceptable.
        14. In the worst case scenario where you don't find any valuable insights, you can quote the
        different figures in the data. But make it sound interesting and unique.

        Rough Example of output (pay attention to the syntax and the tonality but do not blindly copy the statements):
        {EXAMPLE_OUTPUT}
        """

    async def prompt(self, stock_data: list[dict]) -> InsightsResponse:
        """Sends a prompt to the OpenAI GPT API and returns the response."""
        prompt_str = f"""
        For the following stock data, get a minimum of 3 and a maximum of 5 insights per datetime.
        ```json
        {json.dumps(stock_data, indent=4, default=str)}
        ```
        """
        messages = [
            Message(role=GptRoles.SYSTEM, content=self.behavior_instruction),
            Message(role=GptRoles.USER, content=prompt_str)
        ]
        logger.info("Sending prompt to GPT API for insights.")
        try:
            func_response = await openai.ChatCompletion.acreate(
                model=self.model,
                messages=[msg.model_dump() for msg in messages],
                functions=[{
                    "name": "get_stock_insights",
                    "description": "Get a minimum of 3 and a maximum of 5 insights"
                    " from the provided stock data.",
                    "parameters": InsightsResponse.model_json_schema()
                }],
                function_call={"name": "get_stock_insights"}
            )
            response = json.loads(
                func_response.choices[0].message
                .function_call.arguments
            )
            logger.info("Received JSON response from GPT API for insights.")
            if isinstance(response, list):
                response = {"count": len(response), "items": response}
            response["count"] = len(response["items"])
            for item in response["items"]:
                del item["insights"][5:]
        except Exception as exc:  # pylint: disable=broad-except
            logger.error("Failed to get insights from GPT API.")
            logger.error(exc)
            return InsightsResponse(count=0, items=[])
        return InsightsResponse(**response)

    # pylint: disable=unsubscriptable-object
    async def prompt_legacy(self, stock_data: list[dict]) -> InsightsResponse:
        """Sends a prompt to the OpenAI GPT API and returns the response."""
        batch = InsightsRequestsBatch.from_sql_result(stock_data).batch
        if len(batch) > 1:
            prompt_str = f"""
            {Prompts.MULTI_PROMPT_START.value}
            ```json
            {batch[0].to_json()}
            ```
            """
        else:
            prompt_str = f"""
            {Prompts.SINGLE_PROMPT.value}
            ```json
            {batch[0].to_json()}
            ```
            """
        messages = [
            Message(
                role=GptRoles.SYSTEM,
                content=self.behavior_instruction
            ),
            Message(role=GptRoles.USER, content=prompt_str)
        ]
        response = await openai.ChatCompletion.acreate(
            model=self.model,
            messages=[msg.model_dump() for msg in messages],
        )
        res = response.choices[0].message
        if len(batch) == 1:
            insights = [Insights(**dict(zip(
                ["datetime", "insights"],
                *json.loads(res.content).items()
            )))]
            return InsightsResponse(count=1, items=insights)
        prompt_str = f"""
        {Prompts.MULTI_PROMPT_END.value}
        ```json
        {batch[1].to_json()}
        ```
        """
        messages = [
            Message(role=GptRoles.SYSTEM, content=self.behavior_instruction),
            Message(role=GptRoles.ASSISTANT, content=res.content),
            Message(role=GptRoles.USER, content=prompt_str),
        ]
        response = await openai.ChatCompletion.acreate(
            model=self.model,
            messages=[msg.model_dump() for msg in messages],
        )
        try:
            insight_dict = json.loads(response.choices[0].message.content)
        except json.JSONDecodeError:
            extracted = self.insights_pattern.findall(response.choices[0].message.content)
            insight_dict = {
                "count": 1,
                "items": [{
                    "datetime": batch[1].requests[0].datetime,
                    "insights": [
                        {
                            "message": insight[0],
                            "sentiment": insight[1].lower()
                        }
                        for insight in extracted
                    ]
                }]
            }
        except Exception as exc:  # pylint: disable=broad-except
            logger.error("Failed to parse insights.")
            logger.error(exc)
            return InsightsResponse(count=0, items=[])
        return InsightsResponse(**insight_dict)
