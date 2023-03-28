<script lang="ts">
    import "@melloware/coloris/dist/coloris.css";
    import Coloris from "@melloware/coloris";

    Coloris.init();

    let color1: string = "#a343f7";
    let color2: string = "#333333";

</script>

<div class="scroller">
    <div class="page">

        <h3>Page Colors:</h3>
        <!-- INCLUDE RESTORE DEFAULT BTN HERE -->
        <p>Color 1</p>
        <input type="text" class="coloris" data-coloris bind:value={color1}>

        <p>Color 2</p>
        <input type="text" class="coloris" data-coloris bind:value={color2}>



    </div>
</div>

<style>
    .scroller {
        margin-top: var(--titlebarHeight);
        height: calc(100vh - var(--titlebarHeight));
        overflow-y: auto;
    }

    .page {
        margin: 0 auto;
        max-width: 600px;
        padding: 1.0rem;
        overflow-y: auto;
        color: var(--fontColor);
    }

    .coloris {
        border: none;
        background-color: var(--textfieldColor);
        color: var(--fontColor);
        padding: 0.4rem;
        width: 120px;
        height: 1.8rem;
    }
</style>