<script lang="ts">
    import { onMount } from "svelte";
    import { writable } from "svelte/store";

    type Sections = { id: string }[];

    const sections = writable<Sections>([]);

    onMount(() => {
        const sectionElements = document.querySelectorAll("section:not([data-disabled])");
        sections.set(Array.from(sectionElements).map((section) => ({ id: section.id })));
    });
</script>

<div class="banner">
    <div class="title">
        <img src="favicon.ico" alt="logo" />
        <h1>StocksALot</h1>
    </div>
    <nav class="navbar">
        {#each $sections as section}
            <a class="nav-link" href="#{section.id}">{section.id.toUpperCase()}</a>
        {/each}
    </nav>
</div>
<slot />

<style>
    .banner {
        margin: 0;
        padding: 0 1rem;
        display: flex;
        align-items: center;
        justify-content: space-between;
        background-color: #151414;
        color: #aaa;
        overflow: hidden;
        position: relative;
        text-transform: uppercase;
        font-family: "Poppins", monospace;
        box-shadow: 0 0.25rem 0.25rem rgba(0, 0, 0, 0.5);
        z-index: 2;
    }

    .banner .title {
        display: flex;
        flex-direction: row;
        align-items: center;
        justify-content: center;
        gap: 1rem;
    }

    .banner .title img {
        width: 64px;
        height: 64px;
    }

    .banner .title h1 {
        font-size: 2.5vw;
        margin: 0;
        padding: 0.5rem;
    }

    .banner .navbar {
        display: flex;
        flex-direction: row;
        align-items: center;
        justify-content: center;
        gap: 1rem;
    }

    .banner .navbar .nav-link {
        color: #aaa;
        text-decoration: none;
        font-size: 1.25vw;
        padding: 0.5rem;
        transition: all 0.5s ease;
    }

    .banner .navbar .nav-link:hover {
        color: #fff;
        background-color: #000;
    }
</style>
