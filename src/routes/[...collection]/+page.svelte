<script lang="ts">
    import { CreateNote, GetCollection, GetCollectionsPositionals, GetPositional, DeleteNote, UpdateCollectionLastOpen } from "$lib/scripts/db";
    import { DefaultViewModes, EditModes, SetCollectionView, GetCollectionView } from "$lib/scripts/settings";
    import { WindowTitle } from "$lib/scripts/stores";
    import NoteView from "$lib/NoteView.svelte";
    import Toolbar from "$lib/Toolbar.svelte";

    export let data: Collection;

    let notes: Note[] | PositionedNote[];
    let collectionView: CollectionView;
    let collectionElement: HTMLElement;
    let noteInput: HTMLElement;
    let forceFocusId: number | null = null;
    let editMode: EditMode;
    let viewModes: ViewModeCategory[] = DefaultViewModes; // Append positionals later
    let viewMode: ViewMode;

    WindowTitle.set(data.name);

    $: if (noteInput) noteInput.focus();
    $: if (collectionView) SetCollectionView(collectionView);
    $: if (collectionElement) collectionElement.scrollTop = collectionElement.scrollHeight;

    async function initialDataLoad() {
        return await GetCollectionView(data.id).then((value) => {
            if (value) {
                collectionView = value;
            } else {
                collectionView = {
                    id: data.id,
                    name: data.name,
                    editModeId: 1,
                    viewCategoryId: 1,
                    viewModeId: 1
                }
            }
            loadPositionals();
            editMode = getEditModeFromId(collectionView.editModeId);
            viewMode = getViewModeFromId(collectionView.viewCategoryId, collectionView.viewModeId);

            if (viewMode.isSortable) {
                GetCollection(data.id, viewMode.sort)
                    .then((value) => notes = value)
            } else {
                GetPositional(viewMode.id)
                    .then((value) => notes = value)
            }
        }).finally(() => UpdateCollectionLastOpen(data.id));
    }

    async function loadPositionals() {
        return await GetCollectionsPositionals(data.id)
            .then((value) => {
                viewModes[2].options = [];
                for (let positional of value) {
                    positional.isSortable = false;
                    viewModes[2].options.push(positional);
                }
            });
    }

    function getEditModeFromId(id: number): EditMode {
        for (let editMode of EditModes) {
            if (editMode.id === id) {
                return editMode;
            }
        }
        return EditModes[0];
    }

    function getViewModeFromId(catId: number, optId: number): ViewMode {
        for (let cat of viewModes) {
            if (cat.id === catId) {
                for (let opt of cat.options) {
                    if (opt.id === optId) {
                        return opt;
                    }
                }
            }
        }
        return viewModes[0].options[0]; // Consider better error handling next.
    }

    function jumpToPageEnd() {
        collectionElement.scrollTop = collectionElement.scrollHeight;
    }

    function changeEditMode(id: number) {
        editMode = getEditModeFromId(id);
        if (editMode.id === 1) {
            setTimeout(() => {noteInput.focus()}, 0);
        }
    }

    function freeEditAppend(idx: number) {
        //freeEditAppendOpen = true;
        notes.splice(idx, 0, {id: -1, content: "", created_at: "", updated_at: ""});
        notes = notes;
    }

    function changeViewMode(categoryId: number, optionId: number) {
        let oldViewMode = viewMode;
        viewMode = getViewModeFromId(categoryId, optionId);
        collectionView.viewCategoryId = categoryId;
        collectionView.viewModeId = optionId;

        if (viewMode.isSortable) {
            if (oldViewMode.isSortable) {
                switch (optionId) {
                    case 1: notes.sort((a, b) => {
                        return +new Date(a.created_at) - +new Date(b.created_at);
                    }); break;
                    case 2: notes.sort((a, b) => {
                        return +new Date(b.created_at) - +new Date(a.created_at);
                    }); break;
                    case 3: notes.sort((a, b) => {
                        return +new Date(a.updated_at) - +new Date(b.updated_at);
                    }); break;
                    case 4: notes.sort((a, b) => {
                        return +new Date(b.updated_at) - +new Date(a.updated_at);
                    }); break;
                }
                notes = notes;
            } else {
                GetCollection(data.id, viewMode.sort)
                    .then((value) => notes = value);
            }
        } else {
            GetPositional(viewMode.id)
                .then((value) => notes = value);
        }
    }

    async function updateCollection() {
        if (viewMode.isSortable) {
            notes = await GetCollection(data.id, viewMode.sort);
        }
    }

    /**
     * changeType:
     * 0: Enter key
     * 1: Arrow-Up
     * 2: Arrow-Down
     * 3: After Delete (neutral)
    */
    function forceFocusChange(currentFocusIdx: number, changeType: number) {
        if (changeType === 0) {
            if (viewMode.id <= 3) {
                if (notes[currentFocusIdx+1]) {
                    forceFocusId = notes[currentFocusIdx+1].id;
                } else {
                    changeEditMode(0);
                }
            } else {
                // Positional
            }
        } else if (changeType === 1) {
            if (notes[currentFocusIdx-1]) {
                forceFocusId = notes[currentFocusIdx-1].id;
            }
        } else if (changeType === 2) {
            if (notes[currentFocusIdx+1]) {
                forceFocusId = notes[currentFocusIdx+1].id;
            } 
        } else if (changeType === 3) {
            if (notes[currentFocusIdx+1]) {
                forceFocusId = notes[currentFocusIdx+1].id;
            } else if (notes[currentFocusIdx-1]) {
                forceFocusId = notes[currentFocusIdx-1].id;
            }
        }
    }

    async function deleteNoteHandler(noteId: number, noteIdx: number) {
        DeleteNote(noteId)
            .then(() => {updateCollection()
            .then(() => {forceFocusChange(noteIdx-1, 3)})});
    }

    // Ensure these key handlers are only accesible in editing mode
    function editingKeyHandler(event: KeyboardEvent): void {
        const target = event.target as HTMLElement;

        switch (event.key) {
            case "Enter":
                event.preventDefault();
                if (target.innerHTML.length > 0) {
                    CreateNote(target.innerHTML, data.id);
                    updateCollection().then(() => {jumpToPageEnd();});
                    target.innerHTML = "";
                }
                break;
        }
    }
</script>

{#await initialDataLoad() then x}
    <div class="page">
        <Toolbar
            editMode={editMode}
            viewMode={viewMode}
            viewModes={viewModes}
            collection={data}
            changeEditMode={changeEditMode}
            changeViewMode={changeViewMode}
            loadPositionals={loadPositionals}
        />
        <div class="outerCollection" bind:this={collectionElement}>
            <div class="noteCollection">
                {#each notes as note, i}
                    <NoteView 
                        bind:note={note} 
                        idx={i} 
                        editMode={editMode.id} 
                        bind:forceFocusId={forceFocusId} 
                        forceFocusChange={forceFocusChange}
                        deleteNoteHandler={deleteNoteHandler} />
                {/each}
            </div>
        </div>
        {#if editMode.id === 1}
            <div class="outerEntry">
                <div class="noteEntry">
                    <div class="inputArea">
                        <div class="noteInput"
                            contenteditable="true"
                            on:keydown={editingKeyHandler}
                            bind:this={noteInput}
                            placeholder="Append new note">
                        </div>
                    </div>
                </div>
            </div>
        {/if}
    </div>
{/await}

<style>
    .page {
        margin-top: var(--titlebarHeight);
        height: calc(100vh - var(--titlebarHeight));
        display: grid;
        grid-template-rows: min-content 1fr min-content;
    }

    .outerCollection {
        width: 100%;
        overflow-y: auto;
    }

    .noteCollection {
        margin: 0 auto;
        max-width: var(--usableWidth);
        padding: 0.5rem 1.0rem;
    }

    .outerEntry {
        border-top: 1px solid var(--hoverBtnColor);
        width: 100%;
    }

    .noteEntry {
        margin: 0 auto;
        max-width: var(--usableWidth);
        padding: 0.5rem;
    }

    .inputArea {
        padding: 0.25rem;
    }

    .noteInput {
        border-radius: 4px;
        background-color: var(--textfieldColor);
        padding: 0.5rem;
        color: var(--fontColor);
        line-height: 1.84rem;
        min-height: 2.84rem;
        font-size: 1.10rem;
    }

    [contenteditable=true]:empty:before {
        content:attr(placeholder);
        color: grey;
        user-select: none;
        cursor: text;
    }
</style>
