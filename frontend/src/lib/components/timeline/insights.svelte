<script lang="ts">
    import TimelineCard from "./timelinecard.svelte";
    export let data: TimelineData[] = [];

    const accentColors = ["#e22525", "#2577e2", "#30a845", "#e2c625", "#e28525"];

    // Remove duplicate dates
    data = data.filter(
        (item, index, self) => index === self.findIndex((t) => t.datetime === item.datetime)
    );

    const dummyData: TimelineData = {
        datetime: "",
        insights: []
    };
</script>

<!--
    @component
    @name Insights
    @description
        A component that displays the insights from ChatGPT for the latest OHLC data.
    @example
        <Insights data={data} />
-->
<h2>Insights from ChatGPT</h2>
<ul>
    {#each data as item, index (item.datetime)}
        <li style="--accent-color:{accentColors[index % accentColors.length]}">
            <TimelineCard data={item} isOdd={index % 2 == 0} />
        </li>
    {:else}
        {#each { length: 3 } as _, i}
            <li class="dummy" style="--accent-color:{accentColors[i % accentColors.length]}">
                <TimelineCard data={dummyData} isOdd={i % 2 == 0} />
            </li>
        {/each}
    {/each}
</ul>

<style>
    h2 {
        width: 100%;
        text-align: center;
        text-transform: uppercase;
    }

    ul {
        --col-gap: 2rem;
        --row-gap: 2rem;
        --line-w: 0.25rem;
        display: grid;
        grid-template-columns: var(--line-w) 1fr;
        grid-auto-columns: max-content;
        column-gap: var(--col-gap);
        list-style: none;
        min-width: 80vw;
        height: min-content;
        margin-inline: auto;
        max-height: calc(80vh - 1rem);
        overflow-y: auto;
        overflow-x: hidden;
    }

    ul::before {
        content: "";
        grid-column: 1;
        grid-row: 1 / span 20;
        background: var(--line-color);
        border-radius: calc(var(--line-w) / 2);
    }

    ul::-webkit-scrollbar {
        width: 0.5rem;
    }

    ul::-webkit-scrollbar-track {
        background: transparent;
    }

    ul::-webkit-scrollbar-thumb {
        background: var(--line-color);
        border-radius: 0.25rem;
    }

    ul::-webkit-scrollbar-thumb:hover {
        background: var(--accent-color);
    }

    ul::-webkit-scrollbar-thumb:active {
        background: var(--accent-color);
    }

    ul::-webkit-scrollbar-thumb:window-inactive {
        background: var(--accent-color);
    }

    ul li {
        grid-column: 2;
        --inlineP: 1.5rem;
        margin-inline: var(--inlineP);
        grid-row: span 2;
        display: grid;
        grid-template-rows: min-content min-content min-content;
        background: transparent;
        border: 1px solid var(--accent-color);
        border-radius: 0.5rem;
        padding: 1.5rem;
        box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.2);
        transition: scale 0.3s ease-in-out;
        margin-bottom: 2rem;
    }

    ul li:hover {
        scale: 1.1;
    }

    .dummy {
        animation: loading 2s ease-in-out infinite;
    }

    @keyframes loading {
        0% {
            filter: saturate(0);
        }
        50% {
            filter: saturate(1);
        }
        100% {
            filter: saturate(0);
        }
    }

    @media (min-width: 40rem) {
        ul {
            grid-template-columns: 1fr var(--line-w) 1fr;
        }
        ul::before {
            grid-column: 2;
        }
        ul li:nth-child(odd) {
            grid-column: 1;
        }
        ul li:nth-child(even) {
            grid-column: 3;
        }

        ul li:nth-child(2) {
            grid-row: 2/4;
        }
    }

    @media (max-width: 1200px) {
        ul {
            grid-template-columns: 1fr;
            grid-auto-rows: min-content;
            row-gap: var(--row-gap);
            padding: 0;
        }
        ul::before {
            grid-column: 1;
            grid-row: 1;
        }
        ul li {
            padding: 0;
        }
        ul li:nth-child(odd) {
            grid-column: 1;
        }

        ul li:nth-child(even) {
            grid-column: 1;
        }
    }
</style>
