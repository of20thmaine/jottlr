<script lang="ts">
    import "@melloware/coloris/dist/coloris.css";
    import Coloris from "@melloware/coloris";

    export let color: string;
    export let prompt: string;

    Coloris.init();
</script>

<div class="holder">
    <div class="prompt">{prompt}</div>
    <input type="text" class="colorInput" data-coloris bind:value={color}>
</div>

<style>
    .prompt {
        color: var(--fontColor);
    }

    .colorInput {
        border: none;
        background-color: var(--textfieldColor);
        color: var(--fontColor);
        padding: 0.4rem;
        width: 120px;
        height: 1.8rem;
    }
</style>
