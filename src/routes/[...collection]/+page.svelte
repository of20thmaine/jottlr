<script lang="ts">
    import { flip } from 'svelte/animate';
    import { CreateNote, CreatePositionedNote, GetCollection, GetCollectionsPositionals, GetPositional, DeleteNote, DeleteFromPositionedNotes, UpdateCollectionLastOpen } from "$lib/scripts/db";
    import { DefaultViewModes, EditModes, GetPageWidth, ChangeType, SortType, SetCollectionView, GetCollectionView, GetThemeList } from "$lib/scripts/settings";
    import { WindowTitle } from "$lib/scripts/stores";
    import NoteView from "$lib/NoteView.svelte";
    import Toolbar from "$lib/Toolbar.svelte";

    export let data: Collection;

    let notes: Note[];
    let collectionView: CollectionView;
    let collectionElement: HTMLElement;
    let noteInput: HTMLElement;
    let focusNoteId: number | null = null;
    let editMode: EditMode;
    let viewModes: ViewModeCategory[] = DefaultViewModes;
    let themes: Theme[];
    let theme: Theme;
    let viewMode: ViewMode;
    let pageWidth: number = 800;

    WindowTitle.set(data.name);
    GetPageWidth().then((value) => {if (value) pageWidth = value});

    $: if (noteInput) noteInput.focus();
    $: if (collectionView) SetCollectionView(collectionView);
    $: if (collectionElement) collectionElement.scrollTop = collectionElement.scrollHeight;

    $: if (theme) {
        collectionView.themeId = theme.id;
        notes = notes;
    }

    $: if (editMode && viewMode && notes) {
        if (editMode.id === 2 && notes.length === 0) {
            if (!viewMode.isSortable) {
                freeEditAppend(0, 0);
            }
        }
    }

    $: if (viewMode && notes && !viewMode.isSortable) {
        let map = new Map();
        let depth = 0;
        for (let note of notes) {
            if (note.isPositioned) {
                if (note.indents < depth) {
                    for (let i = note.indents+1; i<= depth; ++i) {
                        map.delete(i);
                    }
                }
                depth = note.indents;
                if (map.has(note.indents)) {
                    map.set(note.indents, map.get(note.indents)+1);
                } else {
                    map.set(note.indents, 1)
                }
                note.label = map.get(note.indents);
            }
        }
        notes = notes;
    }

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
                    viewModeId: 1,
                    themeId: 1
                }
            }
            loadPositionals();
            editMode = getEditModeFromId(collectionView.editModeId);
            viewMode = getViewModeFromId(collectionView.viewCategoryId, collectionView.viewModeId);
            GetThemeList().then((value) => {
                themes = value;
                theme = getThemeFromId(collectionView.themeId);
            })

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
        return viewModes[0].options[0];
    }

    function getThemeFromId(id: number): Theme {
        for (let theme of themes) {
            if (theme.id === id) {
                return theme;
            }
        }
        return themes[0];
    }

    function jumpToPageEnd() {
        collectionElement.scrollTop = collectionElement.scrollHeight;
    }

    function changeEditMode(id: number) {
        editMode = getEditModeFromId(id);
        collectionView.editModeId = id;
        if (editMode.id === 1) {
            setTimeout(() => {noteInput.focus()}, 0);
        }
    }

    function freeEditAppend(idx: number, indents: number) {
        notes.splice(idx, 0, {
            id: -1,
            content: "",
            created_at: "",
            updated_at: "",
            isPositioned: true,
            position: idx,
            indents: indents
        });
        notes = notes;
    }

    async function deleteSavedNote(noteId: number, idx: number) {
        if (viewMode.isSortable) {
            await DeleteNote(noteId).then(() => deleteUnsavedNote(idx));
        } else {
            await DeleteFromPositionedNotes(viewMode.id, noteId)
                .then(() => DeleteNote(noteId).then(() => deleteUnsavedNote(idx)));
        }
    }
    
    async function deleteUnsavedNote(idx: number) {
        notes.splice(idx, 1);
        notes = notes;
    }

    function changeViewMode(categoryId: number, optionId: number) {
        let oldViewMode = viewMode;
        viewMode = getViewModeFromId(categoryId, optionId);
        collectionView.viewCategoryId = categoryId;
        collectionView.viewModeId = optionId;

        if (viewMode.isSortable) {
            if (oldViewMode.isSortable) {
                switch (viewMode.sort) {
                    case SortType.Date_Added_Asc: notes.sort((a, b) => {
                        return +new Date(a.created_at) - +new Date(b.created_at);
                    }); break;
                    case SortType.Date_Added_Dsc: notes.sort((a, b) => {
                        return +new Date(b.created_at) - +new Date(a.created_at);
                    }); break;
                    case SortType.Date_Modified_Asc: notes.sort((a, b) => {
                        return +new Date(a.updated_at) - +new Date(b.updated_at);
                    }); break;
                    case SortType.Date_Modified_Dsc: notes.sort((a, b) => {
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
            return await GetCollection(data.id, viewMode.sort)
                .then((value) => notes = value)
        } else {
            return await GetPositional(viewMode.id)
                .then((value) => notes = value)
        }
    }

    function moveNote(oldIdx: number, newIdx: number) {
        if (newIdx < 0 || newIdx > notes.length-1) return;
        notes.splice(newIdx, 0, notes.splice(oldIdx, 1)[0]);
        notes = notes;
        focusNoteId = notes[newIdx].id;
    }

    function onDragStart(event: DragEvent, idx: number) {
        event.dataTransfer?.setData('text/plain', idx.toString());
    }

    function onDragDrop(event: DragEvent, idx: number) {
        let oldIdx = event.dataTransfer?.getData('text/plain');
        if (!oldIdx) return;

        moveNote(parseInt(oldIdx), idx);
    }

    function forceFocusChange(currentFocusIdx: number, changeType: ChangeType, toBeDeleted: boolean) {
        switch (changeType) {
            case ChangeType.Enter:
                if (viewMode.isSortable) {
                    if (notes[currentFocusIdx+1]) {
                        focusNoteId = notes[currentFocusIdx+1].id;
                    } else {
                        changeEditMode(1);
                    }
                } else {
                    if (toBeDeleted) {
                        if (notes[currentFocusIdx+1]) {
                            focusNoteId = notes[currentFocusIdx+1].id;
                        }
                    } else {
                        // @ts-ignore   // isSortable=false means note always positional
                        freeEditAppend(currentFocusIdx+1, notes[currentFocusIdx].indents);
                        focusNoteId = -1;
                    }
                }
                break;
            case ChangeType.ArrowUp:
                if (notes[currentFocusIdx-1]) {
                    focusNoteId = notes[currentFocusIdx-1].id;
                }
                break;
            case ChangeType.ArrowDown:
                if (notes[currentFocusIdx+1]) {
                    focusNoteId = notes[currentFocusIdx+1].id;
                }
                break;
            case ChangeType.AfterDelete:
                if (notes[currentFocusIdx]) {
                    focusNoteId = notes[currentFocusIdx].id;
                } else if (notes[currentFocusIdx-1]) {
                    focusNoteId = notes[currentFocusIdx-1].id;
                }
                break;
        }
    }

    function appendNote() {
        if (!(noteInput.innerHTML.length > 0)) return;

        if (viewMode.isSortable) {
            CreateNote(noteInput.innerHTML, collectionView.id)
                .then(() => {
                    updateCollection().then(() => {
                        jumpToPageEnd();
                        noteInput.innerHTML = "";
                    });
                });
        } else {
            CreateNote(noteInput.innerHTML, collectionView.id)
                .then((value) => {
                    CreatePositionedNote(collectionView.viewModeId, 
                                        value.lastInsertId, 
                                        notes.length,
                                        0)
                        .then(() => {
                            updateCollection().then(() => {
                                jumpToPageEnd();
                                noteInput.innerHTML = "";
                            });
                        });
                });
        }
    }

    function appendModeKeyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                appendNote();
                break;
        }
    }

    function getNoteHolderStyle(note: Note): string {
        if (!note.isPositioned) return "";
        let marginLeft = 0;

        if (typeof theme.noteThemes?.[note.indents]?.marginLeft === 'number') {
            marginLeft = theme.noteThemes[note.indents].marginLeft!;
        } else if (typeof theme.default?.marginLeft === 'number') {
            marginLeft = theme.default.marginLeft * note.indents;
        }
        return "margin-left:" + marginLeft + "px;";
    }
</script>

{#await initialDataLoad() then x}
    <div class="page">
        <Toolbar 
            editMode={editMode}
            viewMode={viewMode}
            viewModes={viewModes}
            bind:theme={theme}
            themes={themes}
            collection={data}
            pageWidth={pageWidth}
            changeEditMode={changeEditMode}
            changeViewMode={changeViewMode}
            loadPositionals={loadPositionals}
        />
        <div class="outerCollection" bind:this={collectionElement}>
            <div class="noteCollection" style="max-width:{pageWidth}px;">
                {#each notes as note, i (note)}
                    <div class="noteHolder" animate:flip="{{duration: 100}}"
                            style="{getNoteHolderStyle(note)}" 
                            draggable="true"
                            on:dragstart={event => onDragStart(event, i)}
                            on:dragover|preventDefault
                            on:drop={event => onDragDrop(event, i)}>
                        <NoteView 
                                idx={i}
                                bind:note={note}
                                bind:collectionView={collectionView}
                                bind:focusNoteId={focusNoteId}
                                viewMode={viewMode}
                                theme={theme}
                                forceFocusChange={forceFocusChange}
                                moveNote={moveNote}
                                deleteSavedNote={deleteSavedNote}
                                deleteUnsavedNote={deleteUnsavedNote} />
                    </div>
                {/each}
            </div>
        </div>
        {#if editMode.id === 1}
            <div class="outerEntry">
                <div class="noteEntry">
                    <div class="appendIco"><i class="bi bi-plus-lg"></i></div>
                    <div class="noteInput"
                        bind:this={noteInput}
                        on:keydown={appendModeKeyHandler}
                        contenteditable="true"
                        placeholder="Append new note"
                        style="max-width:{pageWidth}px;">
                    </div>
                </div>
            </div>
        {/if}
    </div>
{/await}

<style>
    .page {
        /* margin-top: var(--titlebarHeight); */
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
        max-width: 800px;
        padding: 0.5rem 1.0rem;
    }

    .noteHolder {
        display: flex;
        flex-wrap: wrap;
        align-items: baseline;
    }

    .outerEntry {
        border-top: 1px solid var(--hoverBtnColor);
        width: 100%;
    }

    .noteEntry {
        margin: 0 auto;
        max-width: 800px;
        display: flex;
        align-items: baseline;
    }

    .appendIco {
        color: #34be7b;
        font-size: 1.5rem;
        margin: 0 0.75rem;
    }

    .noteInput {
        flex: 1;
        margin: 0.75rem 0.75rem 0.75rem 0;
        padding: 0.5rem 0.75rem;
        border-radius: 4px;
        background-color: var(--textfieldColor);
        color: var(--fontColor);
        line-height: 1.84rem;
        font-size: 1.10rem;
    }

    [contenteditable=true]:empty:before {
        content:attr(placeholder);
        color: grey;
        user-select: none;
        cursor: text;
    }
</style>
