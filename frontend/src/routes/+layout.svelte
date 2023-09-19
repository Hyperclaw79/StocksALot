<script lang="ts">
    import { onMount } from "svelte";
    import { writable } from "svelte/store";

    type Sections = { id: string }[];

    const sections = writable<Sections>([]);

    const hamburgerChecked = writable(false);
    let innerWidth: number;

    onMount(() => {
        const sectionElements = document.querySelectorAll("section:not([data-disabled])");
        sections.set(Array.from(sectionElements).map((section) => ({ id: section.id })));
    });
</script>

<svelte:window bind:innerWidth />
<div class="banner">
    <div class="title">
        <img src="favicon.ico" alt="logo" />
        <h1>StocksALot</h1>
    </div>
    <div class="hamburger">
        <input type="checkbox" bind:checked={$hamburgerChecked} />
        <span />
        <span />
        <span />
    </div>
    <nav class="navbar" class:mobile={innerWidth <= 768} class:hidden={!$hamburgerChecked}>
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

    .banner .hamburger {
        display: none;
        position: relative;
        right: 0;
        z-index: 3;
        -webkit-user-select: none;
        user-select: none;
    }

    .banner .hamburger input {
        display: block;
        width: 40px;
        height: 32px;
        position: absolute;
        top: -7px;
        left: -5px;
        cursor: pointer;
        opacity: 0;
        z-index: 4;
        -webkit-touch-callout: none;
    }

    .banner .hamburger span {
        display: block;
        width: 32px;
        height: 4px;
        margin-bottom: 5px;
        position: relative;
        background: #aaa;
        border-radius: 3px;
        z-index: 3;
        transform-origin: 4px 0px;
        transition: transform 0.5s cubic-bezier(0.77, 0.2, 0.05, 1),
            background 0.5s cubic-bezier(0.77, 0.2, 0.05, 1), opacity 0.55s ease;
    }

    .banner .hamburger span:first-child {
        transform-origin: 0% 0%;
    }

    .banner .hamburger span:nth-last-child(2) {
        transform-origin: 0% 100%;
    }

    .banner .hamburger input:checked ~ span {
        opacity: 1;
        transform: rotate(45deg) translate(-12px, -12px);
        background: #232323;
    }

    .banner .hamburger input:checked ~ span:nth-last-child(3) {
        opacity: 0;
        transform: rotate(0deg) scale(0.2, 0.2);
    }

    .banner .hamburger input:checked ~ span:nth-last-child(2) {
        transform: rotate(-45deg) translate(-8px, 8px);
    }

    .banner .navbar.mobile {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background-color: #151414;
        color: #aaa;
        transition: all 0.5s ease;
        transform-origin: top;
        box-shadow: 0px 8px 8px 0px #000;
    }

    .banner .navbar.mobile .nav-link {
        font-size: 3vw;
    }

    .banner .navbar.mobile.hidden {
        transform: scaleY(0);
    }

    .banner .navbar.mobile.hidden .nav-link {
        opacity: 0;
    }

    @media screen and (max-width: 768px) {
        .banner .title h1 {
            font-size: 4vw;
        }

        .banner .title img {
            width: 32px;
            height: 32px;
        }

        .banner .navbar .nav-link {
            font-size: 2vw;
        }

        .banner .hamburger {
            display: block;
        }
    }
</style>
