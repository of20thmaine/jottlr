<script lang="ts">
    import { flip } from 'svelte/animate';
    import { CreateNote, GetCollection, GetCollectionsPositionals, GetPositional, DeleteNote, DeleteFromPositionedNotes, UpdateCollectionLastOpen } from "$lib/scripts/db";
    import { DefaultViewModes, EditModes, ChangeType, LabelType, SortType, SetCollectionView, GetCollectionView } from "$lib/scripts/settings";
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
    let viewMode: ViewMode;

    WindowTitle.set(data.name);

    $: if (noteInput) noteInput.focus();
    $: if (collectionView) SetCollectionView(collectionView);
    $: if (collectionElement) collectionElement.scrollTop = collectionElement.scrollHeight;

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

    let theme: Theme = {
        name: "Default",
        maxIndents: 4,
        noteThemes: [
            {marginLeft: 0, isLabeled: true, label: LabelType.RomanCaps},
            {marginLeft: 1.0, isLabeled: true, label: LabelType.Numerals},
            {marginLeft: 2.0, isLabeled: true, label: LabelType.AlphabetCaps},
            {marginLeft: 3.0, isLabeled: true, label: LabelType.RomanLowers},
            {marginLeft: 4.0, isLabeled: true, label: LabelType.AlphabetLowers}
        ]
    };

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
        return viewModes[0].options[0];
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
            await DeleteFromPositionedNotes(viewMode.id, noteId).then(() => deleteUnsavedNote(idx));
        }
    }
    
    function deleteUnsavedNote(idx: number) {
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
            GetCollection(data.id, viewMode.sort)
                .then((value) => notes = value)
        } else {
            GetPositional(viewMode.id)
                .then((value) => notes = value)
        }
    }

    function moveNote(oldIdx: number, newIdx: number) {
        if (newIdx < 0 || newIdx > notes.length-1) return;
        notes.splice(newIdx, 0, notes.splice(oldIdx, 1)[0]);
        notes = notes;
        focusNoteId = notes[newIdx].id;
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
        }
    }

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

    function romanizeLabel(number: number): any {
        let numerals: Array<[number, string]> = [
            [1000, 'M'],
            [900, 'CM'],
            [500, 'D'],
            [400, 'CD'],
            [100, 'C'],
            [90, 'XC'],
            [50, 'L'],
            [40, 'XL'],
            [10, 'X'],
            [9, 'IX'],
            [5, 'V'],
            [4, 'IV'],
            [1, 'I']
        ];
        if (number === 0) {
            return "";
        }
        for (let i = 0; i < numerals.length; ++i) {
            if (number >= numerals[i][0]) {
                return numerals[i][1] + romanizeLabel(number - numerals[i][0]);
            }
        }
    }

    function alphabetizeLabel(number: number): any {
        if (number === 0) {
            return "";
        }
        return String.fromCharCode(64 + (number % 26)) + alphabetizeLabel(Math.floor(number / 26));
    }

    function getLabelText(indents: number, label: number): string {
        let labelType = theme.noteThemes[indents].label;

        switch (labelType) {
            case LabelType.RomanCaps:
                return romanizeLabel(label);
            case LabelType.RomanLowers:
                return romanizeLabel(label).toLowerCase();
            case LabelType.AlphabetCaps:
                return alphabetizeLabel(label);
            case LabelType.AlphabetLowers:
                return alphabetizeLabel(label).toLowerCase();
            default:
                return label.toString();
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
                {#each notes as note, i (note)}
                    <div class="noteHolder" animate:flip="{{duration: 100}}"
                            style="margin-left: {note.isPositioned && theme.noteThemes[note.indents] 
                                ? theme.noteThemes[note.indents].marginLeft : 0}rem;">
                        {#if !viewMode.isSortable && note.isPositioned && note.label}
                            {#if theme.noteThemes[note.indents] && theme.noteThemes[note.indents].isLabeled}
                                <div class="label">
                                    {getLabelText(note.indents, note.label)}.
                                </div>
                            {/if}
                        {/if}
                        <div class="note">
                            <NoteView 
                                idx={i}
                                bind:note={note}
                                bind:collectionView={collectionView}
                                bind:focusNoteId={focusNoteId}
                                maxIndents={theme.maxIndents}
                                forceFocusChange={forceFocusChange}
                                moveNote={moveNote}
                                deleteSavedNote={deleteSavedNote}
                                deleteUnsavedNote={deleteUnsavedNote} />
                        </div>
                    </div>
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

    .noteHolder {
        display: flex;
        flex-wrap: wrap;
        align-items: baseline;
    }

    .label {
        width: 60px;
        color: var(--fontColor);
        text-align: center;
    }

    .note {
        flex: 1;
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
