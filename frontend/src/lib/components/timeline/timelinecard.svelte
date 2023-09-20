<script lang="ts">
    export let data: TimelineData;
    export let isOdd = true;

    const colorMap = {
        positive: "#30a845",
        negative: "#e22525",
        neutral: "#2577e2"
    };
</script>

<!--
    @component
    @name TimelineCard
    @description
        A card that displays the insights for a particular date.
    @params
        data: {TimelineData} - The data to be displayed.
        isOdd: {boolean} - Whether the card is odd or even.
    @example
        <TimelineCard data={data} />
-->
<div class="timelinecard">
    <div class="date" class:odd={isOdd}>
        <div class="alt-triangle" />
        {data.datetime}
    </div>
    <div class="insights">
        {#each data.insights as insight}
            <p style="color: {colorMap[insight.sentiment]}">
                {insight.insight}
            </p>
        {/each}
    </div>
</div>

<style>
    .date {
        --dateH: 3rem;
        height: var(--dateH);
        margin-inline: calc(var(--inlineP) * -1);

        text-align: center;
        background-color: var(--accent-color);

        color: white;
        font-size: 1.25rem;
        font-weight: 700;

        display: grid;
        place-content: center;
        position: relative;

        border-radius: calc(var(--dateH) / 2) 0 0 calc(var(--dateH) / 2);

        z-index: 5;
    }

    .date::before {
        content: "";
        width: var(--inlineP);
        aspect-ratio: 1;
        background: var(--accent-color);
        background-image: linear-gradient(rgba(0, 0, 0, 0.2) 100%, transparent);
        position: absolute;
        top: 100%;

        clip-path: polygon(0 0, 100% 0, 0 100%);
        right: 0;
    }

    .date::after {
        content: "";
        position: absolute;
        width: 2rem;
        aspect-ratio: 1;
        background: var(--color);
        border: 0.3rem solid var(--accent-color);
        border-radius: 50%;
        top: 50%;

        transform: translate(50%, -50%);
        right: calc(100% + var(--col-gap) + var(--line-w) / 2);
    }

    .date.odd::before {
        clip-path: polygon(0 0, 100% 0, 100% 100%);
        left: 0;
    }

    .date.odd::after {
        transform: translate(-50%, -50%);
        left: calc(100% + var(--col-gap) + var(--line-w) / 2);
    }
    .date.odd {
        border-radius: 0 calc(var(--dateH) / 2) calc(var(--dateH) / 2) 0;
    }

    .date .alt-triangle {
        display: none;
    }

    .insights {
        background: var(--bgColor);
        filter: brightness(0.8);
        position: relative;
        padding-inline: 1.5rem;
        padding-block-start: 1.5rem;
        padding-block-end: 1.5rem;
        font-weight: 300;
        outline: 1px solid var(--accent-color);
        z-index: 4;
        filter: drop-shadow(0px 0px 4px rgba(0, 0, 0, 1));
    }

    .insights::before {
        content: "";
        position: absolute;
        width: 90%;
        height: 0.5rem;
        background: var(--bgColor);
        left: 50%;
        border-radius: 50%;
        filter: blur(4px);
        transform: translate(-50%, 50%);
    }

    .insights::before {
        z-index: -1;
        bottom: 0.25rem;
    }

    @media (max-width: 1200px) {
        .date,
        .date.odd {
            border-radius: 0;
        }
        .date .alt-triangle {
            display: block;
            position: absolute;
            width: 0;
            height: 0;
            opacity: 75%;
            border-top: 1.5rem solid transparent;
            border-bottom: 1.5rem solid transparent;
            border-right: 1.5rem solid var(--accent-color);
            left: 0;
            top: 50%;
        }
        .date.odd .alt-triangle {
            left: auto;
            right: 0;
            border-right: none;
            border-left: 1.5rem solid var(--accent-color);
        }
        .date::after {
            display: none;
        }
    }
</style>
