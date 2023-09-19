<div class="hero">
    <img class="bg-img" src="stocks-bg.jpg" alt="bg" />
    <div class="image-container">
        <img src="stocksalot-robot.png" alt="StocksALot" />
    </div>
    <div class="text-container">
        <h3>Introducing <big>StocksALot</big></h3>
        <div class="resp-image-container">
            <img src="stocksalot-robot.png" alt="StocksALot" />
        </div>
        <div class="info">
            <ul>
                <li>Watch the latest<sup>*</sup> OHLC values of top 50 US Stocks</li>
                <li>Get AI powered<sup>**</sup> Insights on the latest data</li>
                <li>Track the latest market movers</li>
                <li>More features coming soon....</li>
            </ul>
            <pre>
                <span>*Keep the tab open to see the prices change every hour</span>
                <span
                    >**powered by <a href="https://openai.com/research/gpt-4"
                        >OpenAI's GPT-4 Model</a
                    ></span
                >
            </pre>
        </div>
    </div>
</div>

<style>
    .hero {
        display: flex;
        align-items: center;
        justify-content: space-between;
        background-color: #1e1e1e;
        color: #fff;
        height: 70vh;
        padding-top: 2rem;
        overflow: hidden;
        position: relative;
    }

    .bg-img {
        position: absolute;
        width: 100%;
        height: 100%;
        filter: blur(2px);
        mix-blend-mode: luminosity;
    }

    .image-container {
        max-width: 50vw;
        position: absolute;
        bottom: -10px;
    }

    .resp-image-container {
        display: none;
        max-width: 50vw;
    }

    .image-container img,
    .resp-image-container img {
        display: block;
        max-width: 100%;
        height: auto;
    }

    .text-container {
        max-width: 50%;
        position: absolute;
        left: 50%;
        right: 0;
        top: 0;
        padding-left: 2rem;
        font-size: 2vw;
        text-transform: uppercase;
        font-family: "Poppins", monospace;
    }

    .text-container big {
        color: #acd7e8;
        filter: drop-shadow(0 0 0.5rem #000);
    }

    .text-container ul {
        backdrop-filter: brightness(0.5);
    }

    .text-container pre,
    .text-container sup {
        color: #cfcece;
        font-size: 1vw;
        font-weight: 300;
        font-style: italic;
    }

    .text-container pre {
        display: inline-flex;
        flex-direction: column;
        width: 100%;
        align-items: flex-start;
        padding-left: 25%;
        backdrop-filter: brightness(0.5);
    }

    .text-container pre a {
        text-decoration: underline dashed;
        color: #aaa;
    }

    /* Media Queries */
    @media (max-width: 1200px) {
        .hero {
            flex-direction: column;
            height: 100vw;
        }

        .image-container {
            display: none;
        }

        .resp-image-container {
            display: block;
            max-width: 50vw;
            height: auto;
        }

        .text-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            max-width: 100%;
            position: absolute;
            left: 0;
            right: 0;
            top: 0;
            padding-left: 0;
            font-size: 3vw;
            text-align: center;
        }

        .text-container h3 {
            font-size: 4vw;
        }

        .text-container ul {
            margin-top: 0;
        }

        .text-container pre,
        .text-container sup {
            padding: 1vw;
            font-size: 2.75vw;
        }
    }
</style>
