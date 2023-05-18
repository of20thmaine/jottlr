<script lang="ts">
    import { ClickOutside } from "$lib/scripts/utils";
    import { SelectionAction } from "$lib/scripts/settings";
    import { GetCollectionList, AppendPositionedNote, CutNoteToCollection, CopyNoteToCollection } from '$lib/scripts/db';

    export let showDialog: boolean;
    export let selection: Set<number>;
    export let notes: Note[];
    export let action: SelectionAction;
    export let currentCollection: Collection;
    export let positionals: ViewMode[];
    export let currentViewMode: ViewMode;
    export let deselectAll: () => void;

    let collections: Collection[];
    let selectedCollection: Collection;
    let selectedPositional: ViewMode;
    let showSelect: boolean = false;
    
    async function load() {
        if (!currentViewMode.isSortable) removeCurrentView();
        selectedPositional = positionals[0];

        return await GetCollectionList()
            .then(value => {
                for (let i = 0; i < value.length; ++i) {
                    if (value[i].id === currentCollection.id) {
                        value.splice(i, 1);
                        break;
                    }
                }
                collections = value;
                selectedCollection = collections[0];
            });
    }

    function removeCurrentView() {
        for (let i = 0; i < positionals.length; ++i) {
            if (positionals[i].id === currentViewMode.id) {
                positionals.splice(i, 1);
                return;
            }
        }
    }
</script>

<div class="dialog"
        use:ClickOutside 
        on:outclick={() => showDialog = false}>
    <div class="closeBtn"
            on:click={() => showDialog = false}
            on:keypress={() => showDialog = false}>
        <i class="bi bi-x"></i>
    </div>
    {#await load() then x}
        {#if action === SelectionAction.CopyToPositional}
            {#if selectedPositional}
                <div class="title">Copy {selection.size} notes to...</div>
                <div class="selectHolder">
                    <div class="selector sdsel" class:selectorSelected={showSelect}
                            on:click={() => showSelect = true}
                            on:keypress={() => showSelect = true}>
                        {selectedPositional.name}
                        <i class="mla bi bi-chevron-down"></i>
                    </div>
                    {#if showSelect}
                        <div class="selectorMenu sdselmenu"
                                use:ClickOutside 
                                on:outclick={() => showSelect = false}>
                            {#each positionals as positional}
                                <div class="opt"
                                    on:click={() => {
                                            selectedPositional = positional;
                                            showSelect = false;
                                        }}
                                    on:keypress={() => {
                                            selectedPositional = positional;
                                            showSelect = false;
                                        }}>
                                {positional.name}</div>
                            {/each}
                        </div>
                    {/if}
                </div>
                <div class="approveBtn"
                        on:click={() => {
                            for (const idx of selection) {
                                AppendPositionedNote(selectedPositional.id, notes[idx].id);
                            }
                            deselectAll();
                            showDialog = false;
                        }}
                        on:keypress={() => {
                            for (const idx of selection) {
                                AppendPositionedNote(selectedPositional.id, notes[idx].id);
                            }
                            deselectAll();
                            showDialog = false;
                        }}>
                    Copy
                </div>
            {:else}
                <div class="error">There are no positionals to copy notes to.</div>
            {/if}
        {:else if action === SelectionAction.CopyToCollection}
            {#if selectedCollection}
                <div class="title">Copy {selection.size} notes to...</div>
                <div class="selectHolder">
                    <div class="selector sdsel" class:selectorSelected={showSelect}
                            on:click={() => showSelect = true}
                            on:keypress={() => showSelect = true}>
                        {selectedCollection.name}
                        <i class="mla bi bi-chevron-down"></i>
                    </div>
                    {#if showSelect}
                        <div class="selectorMenu sdselmenu"
                                use:ClickOutside 
                                on:outclick={() => showSelect = false}>
                            {#each collections as collection}
                                <div class="opt"
                                    on:click={() => {
                                            selectedCollection = collection;
                                            showSelect = false;
                                        }}
                                    on:keypress={() => {
                                            selectedCollection = collection;
                                            showSelect = false;
                                        }}>
                                {collection.name}</div>
                            {/each}
                        </div>
                    {/if}
                </div>
                <div class="approveBtn"
                        on:click={() => {
                            for (const idx of selection) {
                                CopyNoteToCollection(notes[idx], selectedCollection.id);
                            }
                            deselectAll();
                            showDialog = false;
                        }}
                        on:keypress={() => {
                            for (const idx of selection) {
                                CopyNoteToCollection(notes[idx], selectedCollection.id);
                            }
                            deselectAll();
                            showDialog = false;
                        }}>
                    Copy
                </div>
            {:else}
                <div class="error">There are no collections to copy notes to.</div>
            {/if}
        {:else if action === SelectionAction.CutToCollection}
            {#if selectedCollection}
                <div class="title">Cut {selection.size} notes to...</div>
                <div class="selectHolder">
                    <div class="selector sdsel" class:selectorSelected={showSelect}
                            on:click={() => showSelect = true}
                            on:keypress={() => showSelect = true}>
                        {selectedCollection.name}
                        <i class="mla bi bi-chevron-down"></i>
                    </div>
                    {#if showSelect}
                        <div class="selectorMenu sdselmenu"
                                use:ClickOutside 
                                on:outclick={() => showSelect = false}>
                            {#each collections as collection}
                                <div class="opt"
                                    on:click={() => {
                                            selectedCollection = collection;
                                            showSelect = false;
                                        }}
                                    on:keypress={() => {
                                            selectedCollection = collection;
                                            showSelect = false;
                                        }}>
                                {collection.name}</div>
                            {/each}
                        </div>
                    {/if}
                </div>
                <div class="approveBtn"
                        on:click={() => {
                            for (const idx of selection) {
                                CutNoteToCollection(notes[idx], selectedCollection.id);
                                notes.splice(idx, 1);
                            }
                            deselectAll();
                            showDialog = false;
                        }}
                        on:keypress={() => {
                            for (const idx of selection) {
                                CutNoteToCollection(notes[idx], selectedCollection.id);
                                notes.splice(idx, 1);
                            }
                            deselectAll();
                            showDialog = false;
                        }}>
                    Cut
                </div>
            {:else}
                <div class="error">There are no collections to cut notes to.</div>
            {/if}
        {/if}
    {/await}
</div>

<style>
    .dialog {
        margin: 0;
        position: absolute;
        z-index: 3;
        top: 40%;
        left: 50%;
        transform: translate(-50%, -50%);
        background-color: var(--backgroundColor);
        border: 1px solid var(--hoverBtnColor);
        width: 260px;
        color: var(--fontColor);
        padding: 1.0rem 1.5rem;
    }

    .closeBtn {
        position: fixed;
        top: 0.5rem;
        right: 0.5rem;
        font-size: 1.25rem;
        cursor: pointer;
    }

    .closeBtn:hover {
        color: red;
    }

    .title {
        margin-bottom: 1.0rem;
    }

    .error {
        margin-right: 0.5rem;
    }

    .sdsel {
        padding: 0.5rem;
        width: 200px;
    }

    .sdselmenu {
        width: 200px;
    }

    .mla {
        margin-left: auto;
    }

    .approveBtn {
        border: 1px solid;
        border-radius: 4px;
        color: var(--highlightColor);
        padding: 0.2rem 1.5rem;
        width: fit-content;
        font-weight: 500;
        margin-top: 1.0rem;
        cursor: pointer;
	    user-select: none;
        margin-left: auto;
    }
</style>
