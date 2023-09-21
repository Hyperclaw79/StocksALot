<script lang="ts">
    export let data: OHLCResponse;

    /**
     * Returns a pretty date time string.
     * @param {string} date
     * @returns {string} A pretty date time string.
     */
    const prettyDateTime = (date: string): string => {
        const d = new Date(date);
        const day = d.getDate();
        const month = d.getMonth() + 1;
        const year = d.getFullYear();
        const hour = d.getHours();
        const minute = d.getMinutes();
        const ampm = hour >= 12 ? "PM" : "AM";
        const formattedHour = hour % 12;
        const formattedMinute = minute < 10 ? `0${minute}` : minute;
        return `${day}/${month}/${year} ${formattedHour}:${formattedMinute} ${ampm}`;
    };

    type priceDict = {
        [key: string]: number;
    };
    const pricesCache = new Map<string, priceDict>();
    const priceChangeColors = ["#41d141", "#c21d1d"];

    const formatter = new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD"
    });

    let innerWidth: number;

    // Reactive Statement to update the price change colors
    $: data.items.forEach((item) => {
        item.colors = item.colors ?? {
            open: "inherit",
            high: "inherit",
            low: "inherit",
            close: "inherit",
            volume: "inherit"
        };
        // Create a cache for the prices if it doesn't exist
        if (!pricesCache.has(item.ticker)) {
            pricesCache.set(item.ticker, {
                open: item.open,
                high: item.high,
                low: item.low,
                close: item.close,
                volume: item.volume
            });
        }
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        const existingPrices = pricesCache.get(item.ticker)!;
        for (const [key, value] of Object.entries(item) as [
            "open" | "high" | "low" | "close" | "volume",
            number
        ][]) {
            if (!["open", "high", "low", "close", "volume"].includes(key)) {
                continue;
            }
            const delta = existingPrices[key] - value;
            if (delta !== 0) {
                existingPrices[key] = value;
                item.colors[key] = delta < 0 ? priceChangeColors[0] : priceChangeColors[1];
            }
        }
    });
</script>

<!--
    @component
    @name Latest
    @description
        A component that displays the latest OHLC data.
    @example
        <Latest data={data} />
-->
<h2>Latest Stock Data</h2>
{#if innerWidth <= 1200 && data.items.length > 0}
    <caption>Recorded on <code><big>{prettyDateTime(data.items[0].datetime)}</big></code></caption>
{/if}
<svelte:window bind:innerWidth />
<div class="stocks">
    <p class="tbl" style="display: {data.count > 0 ? 'none' : 'block'};">Fetching Data...</p>
    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    {#if innerWidth > 1200}
                        <th>Datetime</th>
                        <th>Ticker</th>
                    {/if}
                    <th>Company</th>
                    <th class="numeric">Open</th>
                    <th class="numeric">High</th>
                    <th class="numeric">Low</th>
                    <th class="numeric">Close</th>
                    <th class="numeric">Volume</th>
                </tr>
            </thead>
            <tbody>
                {#each data.items as item}
                    {#if item.datetime}
                        <tr>
                            {#if innerWidth > 1200}
                                <td>{prettyDateTime(item.datetime)}</td>
                                <td>{item.ticker}</td>
                            {/if}
                            <td>
                                {item.company}
                                {#if innerWidth <= 1200}
                                    (<code>{item.ticker}</code>)
                                {/if}
                            </td>
                            <td style="color: {item.colors?.open};" class="numeric">
                                {#if item.colors?.open === priceChangeColors[0]}
                                    &#9650;
                                {:else if item.colors?.open === priceChangeColors[1]}
                                    &#9660;
                                {/if}
                                {formatter.format(item.open)}
                            </td>
                            <td style="color: {item.colors?.high};" class="numeric">
                                {#if item.colors?.high === priceChangeColors[0]}
                                    &#9650;
                                {:else if item.colors?.high === priceChangeColors[1]}
                                    &#9660;
                                {/if}
                                {formatter.format(item.high)}
                            </td>
                            <td style="color: {item.colors?.low};" class="numeric">
                                {#if item.colors?.low === priceChangeColors[0]}
                                    &#9650;
                                {:else if item.colors?.low === priceChangeColors[1]}
                                    &#9660;
                                {/if}
                                {formatter.format(item.low)}
                            </td>
                            <td style="color: {item.colors?.close};" class="numeric">
                                {#if item.colors?.close === priceChangeColors[0]}
                                    &#9650;
                                {:else if item.colors?.close === priceChangeColors[1]}
                                    &#9660;
                                {/if}
                                {formatter.format(item.close)}
                            </td>
                            <td style="color: {item.colors?.volume};" class="numeric">
                                {item.volume?.toLocaleString()}
                            </td>
                        </tr>
                    {:else}
                        <tr class="loading">
                            {#each { length: 8 } as _}
                                <td />
                            {/each}
                        </tr>
                    {/if}
                {:else}
                    {#each { length: 50 } as _}
                        <tr class="loading">
                            {#each { length: 8 } as _}
                                <td />
                            {/each}
                        </tr>
                    {/each}
                {/each}
            </tbody>
        </table>
    </div>
</div>

<style>
    h2 {
        width: 100%;
        text-align: center;
        text-transform: uppercase;
    }

    .stocks {
        position: relative;
        max-height: 90vh;
        overflow-y: auto;
        overflow-x: hidden;
    }

    .stocks::-webkit-scrollbar {
        width: 0.5rem;
    }

    .stocks::-webkit-scrollbar-track {
        background: transparent;
    }

    .stocks::-webkit-scrollbar-thumb {
        background: var(--line-color);
        border-radius: 0.25rem;
    }

    .stocks::-webkit-scrollbar-thumb:hover {
        background: var(--accent-color);
    }

    .stocks::-webkit-scrollbar-thumb:active {
        background: var(--accent-color);
    }

    .stocks::-webkit-scrollbar-thumb:window-inactive {
        background: var(--accent-color);
    }

    .stocks p {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        font-size: 2rem;
        font-weight: 700;
        text-transform: uppercase;
        color: var(--accent-color);
    }

    .table-wrapper {
        overflow-x: auto;
    }

    table {
        width: 100%;
        border-collapse: collapse;
    }

    thead {
        position: sticky;
        top: 0;
        z-index: 1;
        background-color: rgb(87, 87, 87);
    }

    th,
    td {
        text-align: left;
        padding: 16px;
        border: 1px solid #ddd;
    }

    th {
        background-color: rgb(55, 55, 55);
        color: white;
        border-width: 2px;
        filter: drop-shadow(0px 4px 2px black);
        text-transform: uppercase;
    }

    tr:nth-child(even) {
        background-color: #f2f2f2;
        color: #000;
    }

    tr.loading {
        animation: loading 1s infinite;
    }

    .numeric {
        text-align: right;
    }

    @keyframes loading {
        0% {
            opacity: 1;
        }
        50% {
            opacity: 0.5;
        }
        100% {
            opacity: 1;
        }
    }

    @media (max-width: 1200px) {
        table {
            font-size: 80%; /* Reduce font size for smaller screens */
        }

        th,
        td,
        tr {
            padding: 8px; /* Reduce cell padding for smaller screens */
        }

        th {
            font-size: 90%; /* Reduce header font size for smaller screens */
        }

        .stocks p {
            font-size: 1.5rem; /* Reduce fetching data message font size for smaller screens */
        }

        .stocks td:first-child,
        .stocks th:first-child {
            position: sticky;
            left: 0;
            z-index: 9;
            outline: 2px solid #ddd;
        }

        .stocks td:first-child::before,
        .stocks th:first-child::before {
            content: " ";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 100%;
            outline: 2px solid #ddd;
            box-shadow: 2px 0px 4px 2px black;
        }

        .stocks td:first-child {
            background-color: var(--bgColor);
        }

        .stocks tr:nth-child(even) td:first-child {
            background-color: #f2f2f2;
        }
    }
</style>
