<script lang="ts">
    import "@melloware/coloris/dist/coloris.css";
    import Coloris from "@melloware/coloris";

    export let value: string | undefined;

    Coloris.init();
</script>

<div class="row">
    <div class="colorShowHolder" style="margin-right:{value ? "-20px" : 0};">
        {#if value}
            <div class="colorShow" style="background-color:{value};" />
        {/if}
    </div>
    <input type="text" class="colorInput" data-coloris bind:value={value} placeholder="-">
    <div class="restoreDefaultBtn" title="Reset Default"
            on:click={() => value = undefined}
            on:keypress={() => value = undefined}>
        <i class="bi bi-gear"></i>
    </div>
</div>

<style>
    .row {
        display: flex;
        align-items: center;
    }

    .colorShowHolder {
        z-index: 2;
    }

    .colorShow {
        width: 16px;
        height: 16px;
        border-radius: 50%;
    }

    .colorInput {
        border: none;
        border-radius: 4px;
        padding: 0.35rem 0.5rem 0.3rem 0.5rem;
        background-color: var(--textfieldColor);
        font-size: 1.0rem;
        text-align: center;
        color: var(--fontColor);
        width: 110px;
        height: 1.8rem;
        cursor: pointer;
	    user-select: none;
    }

    .colorInput::placeholder {
        color: var(--fontColor);
    }

    .restoreDefaultBtn {
        cursor: pointer;
	    user-select: none;
        margin-left: 0.5rem;
    }
</style>
