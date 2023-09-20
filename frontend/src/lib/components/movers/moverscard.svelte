<script lang="ts">
    export let data: Mover = {
        profile: {
            ticker: "",
            name: "",
            country: "",
            website: "",
            industry: "",
            logo: "",
            market_cap: 0,
            num_shares: 0
        },
        current_metrics: {
            open: 0,
            high: 0,
            low: 0,
            close: 0,
            volume: 0
        },
        metric_deltas: {
            open: 0,
            high: 0,
            low: 0,
            close: 0,
            volume: 0
        }
    };

    const formatter = new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD"
    });
</script>

<!--
    @component
    @name MoversCard
    @description
        A card that displays the information for a particular mover.
    @example
        <MoversCard data={data} />
-->
<div class="card">
    <div class="card-header">
        <img
            class="card-logo"
            class:dummy={data.profile.ticker === ""}
            src={data.profile.logo}
            alt={data.profile.ticker}
        />
        <div>
            <div class="card-title">
                <a
                    href={data.profile.website}
                    class:dummy={data.profile.ticker === ""}
                    target="_blank"
                    rel="noopener noreferrer"
                >
                    {data.profile.name || "Company Name"}
                </a>
            </div>
            <div class="card-subtitle">
                <span class:dummy={data.profile.ticker === ""}
                    >{data.profile.ticker || "Ticker"} - {data.profile.country || "US"}</span
                >
                {#if data.profile.exchange}
                    @ {data.profile.exchange}
                {:else if data.profile.ticker === ""}
                    <span class="dummy">@ Exchange</span>
                {/if}
            </div>
        </div>
    </div>
    <div class="card-section current-metrics">
        <table>
            <thead>
                <tr>
                    <th>Open</th>
                    <th>High</th>
                    <th>Low</th>
                    <th>Close</th>
                    <th>Volume</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    {#if data.metric_deltas.open > 0}
                        <td style="color: #41d141;">
                            {formatter.format(data.current_metrics.open)}
                        </td>
                    {:else if data.metric_deltas.open < 0}
                        <td style="color: #c21d1d;">
                            {formatter.format(data.current_metrics.open)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.current_metrics.open)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.high > 0}
                        <td style="color: #41d141;">
                            {formatter.format(data.current_metrics.high)}
                        </td>
                    {:else if data.metric_deltas.high < 0}
                        <td style="color: #c21d1d;">
                            {formatter.format(data.current_metrics.high)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.current_metrics.high)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.low > 0}
                        <td style="color: #41d141;">
                            {formatter.format(data.current_metrics.low)}
                        </td>
                    {:else if data.metric_deltas.low < 0}
                        <td style="color: #c21d1d;">
                            {formatter.format(data.current_metrics.low)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.current_metrics.low)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.close > 0}
                        <td style="color: #41d141;">
                            {formatter.format(data.current_metrics.close)}
                        </td>
                    {:else if data.metric_deltas.close < 0}
                        <td style="color: #c21d1d;">
                            {formatter.format(data.current_metrics.close)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.current_metrics.close)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.volume > 0}
                        <td style="color: #41d141;">
                            {data.current_metrics.volume.toLocaleString()}
                        </td>
                    {:else if data.metric_deltas.volume < 0}
                        <td style="color: #c21d1d;">
                            {data.current_metrics.volume.toLocaleString()}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{data.current_metrics.volume.toLocaleString()}</span
                            >
                        </td>
                    {/if}
                </tr>
                <tr>
                    {#if data.metric_deltas.open > 0}
                        <td style="color: #41d141;">
                            &#9650; {formatter.format(data.metric_deltas.open)}
                        </td>
                    {:else if data.metric_deltas.open < 0}
                        <td style="color: #c21d1d;">
                            &#9660; {formatter.format(data.metric_deltas.open)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.metric_deltas.open)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.high > 0}
                        <td style="color: #41d141;">
                            &#9650; {formatter.format(data.metric_deltas.high)}
                        </td>
                    {:else if data.metric_deltas.high < 0}
                        <td style="color: #c21d1d;">
                            &#9660; {formatter.format(data.metric_deltas.high)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.metric_deltas.high)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.low > 0}
                        <td style="color: #41d141;">
                            &#9650; {formatter.format(data.metric_deltas.low)}
                        </td>
                    {:else if data.metric_deltas.low < 0}
                        <td style="color: #c21d1d;">
                            &#9660; {formatter.format(data.metric_deltas.low)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.metric_deltas.low)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.close > 0}
                        <td style="color: #41d141;">
                            &#9650; {formatter.format(data.metric_deltas.close)}
                        </td>
                    {:else if data.metric_deltas.close < 0}
                        <td style="color: #c21d1d;">
                            &#9660; {formatter.format(data.metric_deltas.close)}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{formatter.format(data.metric_deltas.close)}</span
                            >
                        </td>
                    {/if}
                    {#if data.metric_deltas.volume > 0}
                        <td style="color: #41d141;">
                            &#9650; {data.metric_deltas.volume.toLocaleString()}
                        </td>
                    {:else if data.metric_deltas.volume < 0}
                        <td style="color: #c21d1d;">
                            &#9660; {data.metric_deltas.volume.toLocaleString()}
                        </td>
                    {:else}
                        <td>
                            <span class:dummy={data.profile.ticker === ""}
                                >{data.metric_deltas.volume.toLocaleString()}</span
                            >
                        </td>
                    {/if}
                </tr>
            </tbody>
        </table>
    </div>
    <div class="card-details">
        <div class="info">
            {#if data.profile.industry}
                <p>🏭 Industry</p>
                <p>{data.profile.industry}</p>
            {/if}
        </div>
        <hr class:dummy={data.profile.ticker === ""} />
        <div class="info">
            {#if data.profile.market_cap}
                <p>💰 Market Cap</p>
                <p>{formatter.format(data.profile.market_cap)}</p>
            {/if}
        </div>
        <hr class:dummy={data.profile.ticker === ""} />
        <div class="info">
            {#if data.profile.num_shares}
                <p>📰 Outstanding Shares</p>
                <p>{data.profile.num_shares.toLocaleString()}</p>
            {/if}
        </div>
        <hr class:dummy={data.profile.ticker === ""} />
        <div class="info">
            {#if data.profile.phone}
                <p>📞 Phone</p>
                <p>{data.profile.phone}</p>
            {/if}
        </div>
        <hr class:dummy={data.profile.ticker === ""} />
    </div>
</div>

<style>
    .card {
        background-color: var(--card-bg);
        backdrop-filter: brightness(0.8);
        border-radius: 2vw;
        box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
        color: var(--text-color);
        display: flex;
        flex-direction: column;
        padding: 1.5rem;
        width: 36vw;
        overflow: hidden;
        max-height: 18vh;
        transition: max-height ease-in-out 0.5s, border-radius ease-in-out 0.1s;
        cursor: pointer;
        margin-bottom: 2rem;
    }

    .card-header {
        display: flex;
        align-items: center;
    }

    .card-logo {
        width: 50px;
        height: 50px;
        border-radius: 50%;
        margin-right: 12px;
    }

    .card-title {
        font-size: 18px;
        font-weight: bold;
    }

    .card-title a {
        color: var(--text-color);
        text-decoration: underline;
    }

    .card-subtitle {
        font-size: 14px;
        color: var(--secondary-text-color);
    }

    .card-section {
        margin-top: 16px;
    }

    .current-metrics {
        display: flex;
    }

    .current-metrics table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
        border: 1px solid #ddd;
    }

    .current-metrics thead {
        position: sticky;
        top: 0;
        z-index: 1;
        background-color: rgb(87, 87, 87);
    }

    .current-metrics th,
    .current-metrics td {
        text-align: right;
        padding: 8px;
        border: 1px solid #ddd;
    }

    .current-metrics th {
        background-color: rgb(55, 55, 55);
        color: white;
        border-width: 2px;
        filter: drop-shadow(0px 4px 2px black);
        text-transform: uppercase;
    }

    .current-metrics tr:nth-child(even) {
        background-color: #f2f2f2;
        color: #000;
        display: none;
    }

    span {
        margin: 8px 0;
    }

    .card:hover {
        max-height: 80vh;
        transition: max-height ease-in-out 0.5s;
    }

    .card-details {
        display: none;
        transition: opacity 0.5s;
        background-color: rgb(55, 55, 55);
        padding: 1rem;
        margin-top: 0.5rem;
    }

    .card-details .info {
        display: flex;
        justify-content: space-between;
    }

    .card-details .info p {
        margin: 0;
    }

    .card-details .info p:first-child {
        font-weight: bold;
    }

    .card-details .info p:last-child {
        text-align: right;
    }

    hr {
        margin: 0.5rem 0;
        border: 0;
        border-top: 1px solid var(--accent-color);
    }

    .card:hover {
        border-radius: 0;
    }

    .card:hover :global(~ .card:not(:hover)) {
        filter: blur(2px);
    }

    .card:hover tr:nth-child(even) {
        display: table-row;
    }

    .card:hover .card-details {
        display: grid;
        opacity: 1;
    }

    .dummy {
        animation: loading 2s ease-in-out infinite;
    }

    @keyframes loading {
        0% {
            filter: blur(2px);
        }
        50% {
            filter: blur(0);
        }
        100% {
            filter: blur(2px);
        }
    }

    /* Media Queries */
    @media (max-width: 1200px) {
        .card {
            width: 80vw;
            padding: 1rem;
            border-radius: 0;
            max-height: 100%;
        }

        .card tr:nth-child(even) {
            display: table-row;
        }

        .card .card-header {
            width: 100%;
            justify-content: center;
            gap: 2rem;
            box-shadow: 0px 4px 10px rgba(0, 0, 0, 1);
        }

        .card .card-title {
            font-size: 2.5vw;
        }

        .card .card-subtitle {
            font-size: 1.5vw;
        }

        .card .card-details {
            display: grid;
            opacity: 1;
        }
    }

    @media (max-width: 640px) {
        .card {
            width: 90vw;
            padding: 0;
        }

        .card .card-logo {
            width: 40px;
            height: 40px;
            margin-right: 8px;
        }

        .card .card-title {
            font-size: 4vw;
        }

        .card .card-subtitle {
            font-size: 3vw;
        }

        .card .current-metrics th {
            font-size: 3vw;
        }

        .card .current-metrics td {
            font-size: 2.8vw;
        }

        .card .card-details {
            padding: 0.5rem;
        }

        .card .card-details .info p:first-child {
            font-size: 3vw;
        }

        .card .card-details .info p:last-child {
            font-size: 2.8vw;
        }
    }
</style>
