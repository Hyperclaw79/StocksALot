export const ssr = false;

/** Disabling this since the fetch takes too long.

export const load = async ({ fetch }) => {
    let res = await fetch("/api/latest");
    const insights = await res.json();
    res = await fetch("/api/movers");
    const movers = await res.json();
    res = await fetch("/api/insights");
    const latest = await res.json();
    return {
        latest,
        movers,
        insights
    };
};

*/
