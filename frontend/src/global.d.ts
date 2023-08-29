declare global {
    type insight = {
        sentiment: "positive" | "negative" | "neutral";
        insight: string;
    };

    type TimelineData = {
        datetime: string;
        insights: insight[];
    };

    type InsightsResponse = {
        count: number;
        items: TimelineData[];
    };

    type ColorDict = {
        open: string;
        high: string;
        low: string;
        close: string;
        volume: string;
    };

    type OHLC = {
        datetime: string;
        timestamp: number;
        ticker: string;
        company: string;
        open: float;
        high: float;
        low: float;
        close: float;
        volume: number;
        colors?: ColorDict;
    };

    type OHLCOriginal = {
        datetime: OHLC["datetime"];
        timestamp: OHLC["timestamp"];
        ticker: OHLC["ticker"];
        name: OHLC["company"];
        open: OHLC["open"];
        high: OHLC["high"];
        low: OHLC["low"];
        close: OHLC["close"];
        volume: OHLC["volume"];
    };

    type OHLCResponse = {
        count: number;
        items: OHLC[];
    };

    type OHLCOriginalResponse = {
        count: number;
        items: OHLCOriginal[];
    };

    type Profile = {
        ticker: string;
        name: string;
        website: string;
        country: string;
        logo: string;
        industry?: string;
        exchange?: string;
        phone?: string;
        market_cap?: number;
        num_shares?: number;
    };

    type Metrics = {
        open: float;
        high: float;
        low: float;
        close: float;
        volume: number;
    };

    type Mover = {
        profile: Profile;
        current_metrics: Metrics;
        metric_deltas: Metrics;
    };

    type Movers = {
        count: number;
        items: Mover[];
    };
}

export {};
