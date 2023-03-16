<script lang="ts">
    import { onMount } from "svelte";
    import { UpdateNote } from "$lib/scripts/db";

    export let note: Note;
    export let idx: number;
    export let editMode: number;
    export let forceFocusId: number | null;
    export let forceFocusChange: (x: number, y: number) => void;
    export let deleteNoteHandler: (x: number, y: number) => void;

    let node: HTMLElement;
    let hasFocus: boolean = false;
    let noteBeingSaved: boolean = false;

    onMount(() => {
        // Eventually for free edit appending.
        if (note.id === -1) {
            node.focus();
        }
    });

    $: if (forceFocusId === note.id) {
        forceFocus();
    }

    $: {
        if (note.content.length > 0) {
            noteBeingSaved = true;
            UpdateNote(note.id, note.content).then(() => {
                setTimeout(() => {noteBeingSaved = false}, 500);
            });
        }
    }

    function forceFocus() {
        let range = document.createRange();
        range.selectNodeContents(node);
        range.collapse(false);
        let sel = window.getSelection();
        sel?.removeAllRanges();
        sel?.addRange(range);
        node.focus();
        range.detach();
    }

    function onBlurHandler() {
        hasFocus = false;
        if (note.content.length === 0) {
            deleteNoteHandler(note.id, idx);
        }
    }

    function freeEditKeyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                forceFocusChange(idx, 0);
                return;
            case "Delete":
                event.preventDefault();
                deleteNoteHandler(note.id, idx);
                return;
            case "ArrowDown":
                event.preventDefault();
                forceFocusChange(idx, 2);
                return;
            case "ArrowUp":
                event.preventDefault();
                forceFocusChange(idx, 1);
                return;
        }
    }
</script>

{#if editMode === 2}
    <div class="noteContent"
        contenteditable="true"
        bind:this={node}
        bind:innerHTML={note.content}
        on:keydown={freeEditKeyHandler}
        on:focus={() => {hasFocus = true; forceFocusId = null;}}
        on:blur={() => {onBlurHandler()}}
        placeholder="Empty notes are not saved">
    </div>
    {#if hasFocus}
        {#if noteBeingSaved}
            <div class="noteIdc loader"></div>
        {:else if note.content.length === 0}
            <div class="noteIdc toBeDeleted"><i class="bi bi-x"></i></div>
        {:else}
            <div class="noteIdc saved"><i class="bi bi-check-lg"></i></div>
        {/if}
    {/if}
{:else}
    <div class="noteContent"
        contenteditable="false"
        bind:innerHTML={note.content}>
    </div>
{/if}

<style>
    .noteContent {
        border-radius: 4px;
        background-color: var(--textfieldColor);
        padding: 0.5rem 0.75rem;
        margin: 1.0rem 0;
        color: var(--fontColor);
        line-height: 1.84rem;
        font-size: 1.10rem;
    }

    [contenteditable=true]:empty:before {
        content:attr(placeholder);
        color: grey;
    }

    .noteIdc {
        position: relative;
        float: right;
        z-index: 2;
        margin-top: -1.0rem;
        margin-right: -0.5rem;
    }

    .saved {
        color: #3cb452;
    }

    .toBeDeleted {
        color: #BE3455;
    }

    .loader {
        border: 3px solid var(--hoverBtnColor);
        border-top: 3px solid #F5DF4D;
        border-radius: 50%;
        width: 13px;
        height: 13px;
        animation: spin 0.75s linear infinite;
        margin-left: auto;
    }

    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg);}
    }
</style>
