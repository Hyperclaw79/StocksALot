<script lang="ts">
    import MoversCard from "./moverscard.svelte";
    export let data: Movers = {
        count: 0,
        items: []
    };
    // Remove duplicate tickers
    data.items = data.items.filter(
        (item, index, self) =>
            index === self.findIndex((t) => t.profile.ticker === item.profile.ticker)
    );
</script>

<!--
    @component
    @name Movers
    @description
        A component that displays the top Market Movers.
    @example
        <Movers data={data} />
-->
<h2>Top Market Movers</h2>
<div>
    {#if data.count > 0}
        {#each data.items as item (item.profile.ticker)}
            <MoversCard data={item} />
        {/each}
    {:else}
        {#each { length: 10 } as _}
            <MoversCard />
        {/each}
    {/if}
</div>

<style>
    h2 {
        width: 100%;
        text-align: center;
        text-transform: uppercase;
    }

    div {
        display: flex;
        justify-content: space-evenly;
        flex-wrap: wrap;
        gap: 2rem;
    }
</style>
