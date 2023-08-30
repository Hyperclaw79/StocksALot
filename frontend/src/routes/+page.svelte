<script lang="ts">
    import Latest from "$lib/components/latest/latest.svelte";
    import Insights from "$lib/components/timeline/insights.svelte";
    import MoversComponent from "$lib/components/movers/movers.svelte";

    type dataProp = {
        insights: InsightsResponse;
        latest: OHLCResponse;
        movers: Movers;
    };

    const immediate = 0;
    const secs_10 = 10 * 1000;
    const hr_1 = 60 * 60 * 1000;
    const intervals = [immediate, secs_10, hr_1];
    let loadStage = 0;

    let data: dataProp = {
        insights: {
            count: 0,
            items: []
        },
        latest: {
            count: 0,
            items: []
        },
        movers: {
            count: 0,
            items: []
        }
    };

    /**
     * Refreshes the data as per the required intervals.
     */
    const refreshData = async () => {
        if (loadStage === 0) {
            loadStage = 1;
        }
        let latest, movers, insights;
        if ((loadStage <= 1 && data.latest.count == 0) || loadStage > 1) {
            latest = await getLatest();
            data.latest = latest;
        }
        if ((loadStage <= 1 && data.movers.count == 0) || loadStage > 1) {
            movers = await getMovers();
            data.movers = movers;
        }
        if ((loadStage <= 1 && data.insights.count == 0) || loadStage > 1) {
            insights = await getInsights();
            data.insights = insights;
        }
        if ((latest?.count || 0) > 0 && (movers?.count || 0) > 0 && (insights?.count || 0) > 0) {
            loadStage = 2;
        }
        // Recursive call to refresh data
        _timeout = setTimeout(async () => {
            await refreshData();
        }, intervals[loadStage]);
    };

    let _timeout = setTimeout(async () => {
        await refreshData();
    }, intervals[loadStage]);

    /**
     * Fetches the latest OHLC data from the API.
     * @returns {Promise<OHLCResponse>} The latest OHLC data.
     */
    const getLatest = async (): Promise<OHLCResponse> => {
        const res = await fetch("/api/latest");
        const jsonLatest: OHLCResponse = await res.json();
        return jsonLatest;
    };

    /**
     * Fetches the top Market Movers from the API.
     * @returns {Promise<Movers>} The top Market Movers.
     */
    const getMovers = async (): Promise<Movers> => {
        const res = await fetch("/api/movers");
        const jsonMovers: Movers = await res.json();
        // Update the existing movers
        jsonMovers.items.forEach((item) => {
            const index = data.movers.items.findIndex(
                (t) => t.profile.ticker === item.profile.ticker
            );
            if (index !== -1) {
                data.movers.items[index] = item;
            }
        });
        return jsonMovers;
    };

    /**
     * Fetches the Insights from the API.
     * @returns {Promise<InsightsResponse>} The Insights.
     */
    const getInsights = async (): Promise<InsightsResponse> => {
        const res = await fetch("/api/insights");
        const jsonInsights: InsightsResponse = await res.json();
        // Update the existing insights
        const insights = [...data.insights.items, ...jsonInsights.items].filter(
            (item, index, self) => index === self.findIndex((t) => t.datetime === item.datetime)
        );
        insights.sort((a, b) => {
            return new Date(b.datetime).getTime() - new Date(a.datetime).getTime();
        });
        return { count: insights.length, items: insights };
    };
</script>

<!--
    @component
    The main component which holds together the different sections of the page.  
 -->
<section id="latest">
    <Latest data={data.latest} />
</section>
<section id="insights">
    <Insights data={data.insights.items} />
</section>
<section id="movers">
    <MoversComponent data={data.movers} />
</section>
<section id="historyCharts">
    <h2>Next Section coming soon...</h2>
</section>

<style>
    @import url("https://fonts.googleapis.com/css2?family=Poppins:wght@300;500;700&display=swap");

    :root {
        --color: rgba(245, 245, 245);
        --bgColor: rgba(30, 30, 30);
        --accent-color: rgb(225, 225, 225);
        --line-color: rgb(45, 45, 45);
    }

    *,
    *::before,
    *::after {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    section {
        min-height: 100vh;
        display: flex;
        flex-direction: column;
        padding: 2rem;
        font-family: "Poppins", sans-serif;
        color: var(--color);
        background: var(--bgColor);
        box-shadow: 0 0 1rem rgba(0, 0, 0, 0.5);
    }

    section#movers {
        flex-wrap: wrap;
        padding: 0.05rem;
    }

    h2 {
        width: 100%;
        text-align: center;
        text-transform: uppercase;
    }
</style>
