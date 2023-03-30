<script lang="ts">
    import ColorSelector from "$lib/ColorSelector.svelte";

</script>

<div class="scroller">
    <div class="page">

        <h3>Page Colors:</h3>

        <ColorSelector
            color={""}
            prompt={""}
        />

    </div>
</div>

<style>
    .page {
        margin-top: var(--titlebarHeight);
        margin: 0 auto;
        max-width: 600px;
        padding: 1.0rem;
        overflow-y: auto;
        color: var(--fontColor);
    }
</style>