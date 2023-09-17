# pylint: skip-file
import pytest
from .fixtures import gpt_client_fixture
from database.gpt_client import GptClient


@pytest.mark.parametrize("data, prompt_call_count", [
    ([
        [
            {
                "datetime": "2021-01-01 00:00:00",
            },
            {
                "datetime": "2021-01-01 01:00:00",
            }
        ],
        # Repeated data
        [
            {
                "datetime": "2021-01-01 00:00:00",
            },
            {
                "datetime": "2021-01-01 01:00:00",
            }
        ]
    ], 1),
    ([
        [
            {
                "datetime": "2021-01-01 00:00:00",
            },
            {
                "datetime": "2021-01-01 01:00:00",
            }
        ],
        # New data
        [
            {
                "datetime": "2021-01-01 01:00:00",
            },
            {
                "datetime": "2021-01-01 02:00:00",
            }
        ]
    ], 2)
])
async def test_prompt(gpt_client_fixture, data, prompt_call_count):
    """Tests the prompt method."""
    gpt_client = gpt_client_fixture("test key")
    for msg in data:
        await gpt_client.prompt(msg)
    assert gpt_client.cached_insights is not None
    assert gpt_client.last_prompted_datetime == msg[-1]["datetime"]
    # Call Count is an indication of whether the cached insights were used or not.
    assert gpt_client._send_prompt.call_count == prompt_call_count


@pytest.mark.parametrize("insights, expected", [
    (
        [
            {
                "datetime": "2021-01-01 00:00:00",
                "insights": [
                    {
                        "message": "This is a positive insight.",
                        "sentiment": "positive"
                    },
                    {
                        "message": "This is a negative insight.",
                        "sentiment": "negative"
                    },
                    {
                        "message": "This is a neutral insight.",
                        "sentiment": "neutral"
                    }
                ]
            }
        ],
        [
            {
                "datetime": "2021-01-01 00:00:00",
                "insights": [
                    {
                        "message": "This is a positive insight.",
                        "sentiment": "positive"
                    },
                    {
                        "message": "This is a negative insight.",
                        "sentiment": "negative"
                    },
                    {
                        "message": "This is a neutral insight.",
                        "sentiment": "neutral"
                    }
                ]
            }
        ]
    ),
    (
        [
            {
                "datetime": "2021-01-01 00:00:00",
                "insights": [
                    {
                        "message": "This is a positive insight. (Sentiment: Positive)",
                        "sentiment": "positive"
                    },
                    {
                        "message": "This is a negative insight. (Sentiment: Negative)",
                        "sentiment": "negative"
                    },
                    {
                        "message": "This is a neutral insight. (Sentiment: neutral)",
                        "sentiment": "neutral"
                    }
                ]
            }
        ],
        [
            {
                "datetime": "2021-01-01 00:00:00",
                "insights": [
                    {
                        "message": "This is a positive insight.",
                        "sentiment": "positive"
                    },
                    {
                        "message": "This is a negative insight.",
                        "sentiment": "negative"
                    },
                    {
                        "message": "This is a neutral insight.",
                        "sentiment": "neutral"
                    }
                ]
            }
        ]
    )
])
async def test_clean_insights(insights, expected):
    """Tests the clean_insights method."""
    input_insights = insights[:]
    GptClient.clean_insights(input_insights)
    assert input_insights == expected
