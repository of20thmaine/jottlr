<script lang="ts">
    import { CreateNote, CreatePositionedNote, UpdateNote, UpdateNotePosition } from "$lib/scripts/db";
    import { ChangeType } from "$lib/scripts/settings";

    export let note: Note;
    export let idx: number;
    export let collectionView: CollectionView;
    export let focusNoteId: number | null;
    export let maxIndents: number;
    export let forceFocusChange: (currentFocusIdx: number, changeType: ChangeType, toBeDeleted: boolean) => void;
    export let moveNote: (oldIdx: number, newIdx: number) => void;
    export let deleteSavedNote: (noteId: number) => void;
    export let deleteUnsavedNote: (idx: number) => void;

    let node: HTMLElement;

    $: if (node && focusNoteId === note.id) {
        forceFocus();
    }

    $: if (note.isPositioned) {
        if (note.position !== idx) {
            UpdateNotePosition(collectionView.viewModeId, note.id, idx, note.indents);
            note.position = idx;
        }
    }

    async function saveNote() {
        if (noteCanBeSaved()) {
            if (note.id === -1) {
                CreateNote(note.content, collectionView.id)
                    .then((value) => {
                        note.id = value.lastInsertId;
                        if (note.isPositioned) {
                            CreatePositionedNote(collectionView.viewModeId, note.id, note.position, note.indents);
                        }
                    });
            } else {
                UpdateNote(note.id, note.content);
            }
        }
    }

    function noteCanBeSaved(): boolean {
        if (note.content.length === 0) {
            return false;
        }
        return true;
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

    function onFocusLostHandler() {
        if (!noteCanBeSaved() && note.id === -1) {
            deleteUnsavedNote(idx);
        } else if (!noteCanBeSaved()) {
            deleteSavedNote(note.id);
        }
    }

    function debounce(callback: () => void, wait: number) {
        let timeout: number | undefined;
        return (...args: any) => {
            clearTimeout(timeout);
            timeout = setTimeout(function (this: any) { callback.apply(this, args); }, wait);
        };
    }

    function changeIndents(delta: number) {
        if (note.isPositioned) {
            if (note.indents + delta >= 0 && note.indents + delta <= maxIndents) {
                note.indents += delta;
                UpdateNotePosition(collectionView.viewModeId, note.id, idx, note.indents);
            }
        }
    }

    function freeEditKeyHandler(event: KeyboardEvent): void {
        switch (event.key) {
            case "Enter":
                event.preventDefault();
                forceFocusChange(idx, ChangeType.Enter, !noteCanBeSaved());
                return;
            case "ArrowDown":
                event.preventDefault();
                if (event.ctrlKey) {
                    moveNote(idx, idx+1)
                } else {
                    forceFocusChange(idx, ChangeType.ArrowDown, !noteCanBeSaved());
                }
                return;
            case "ArrowUp":
                event.preventDefault();
                if (event.ctrlKey) {
                    moveNote(idx, idx-1)
                } else {
                    forceFocusChange(idx, ChangeType.ArrowUp, !noteCanBeSaved());
                }
                return;
            case "Delete":
                event.preventDefault();
                if (note.id === -1) {
                    deleteUnsavedNote(idx);
                } else {
                    deleteSavedNote(note.id);
                }
                return;
            case "Tab":
                event.preventDefault();
                if (event.shiftKey) {
                    changeIndents(-1);
                } else {
                    changeIndents(1);
                }
                return;
            case "ArrowLeft":
                event.preventDefault();
                if (event.ctrlKey) {
                    changeIndents(-1);
                }
                return;
            case "ArrowRight":
                event.preventDefault();
                if (event.ctrlKey) {
                    changeIndents(1);
                }
                return;
        }
    }
</script>

{#if collectionView.editModeId === 2}
    <div class="noteContent"
        contenteditable="true"
        placeholder="Empty notes are not saved"
        bind:this={node}
        bind:innerHTML={note.content}
        on:keydown={freeEditKeyHandler}
        on:focusout={() => onFocusLostHandler()}
        on:focus={() => focusNoteId = null}
        on:keyup={debounce(async () => {
                await saveNote();
            }, 1000)}>
    </div>
{:else}
    <div class="noteContent"
        contenteditable="false"
        bind:this={node}
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
        user-select: none;
        cursor: text;
    }
</style>
