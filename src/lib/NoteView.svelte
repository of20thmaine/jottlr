<script lang="ts">
    import { CreateNote, CreatePositionedNote, UpdateNote, UpdateNotePosition } from "$lib/scripts/db";
    import { ChangeType, LabelType } from "$lib/scripts/settings";

    export let note: Note;
    export let idx: number;
    export let collectionView: CollectionView;
    export let focusNoteId: number | null;
    export let maxIndents: number;
    export let viewMode: ViewMode;
    export let theme: Theme;
    export let forceFocusChange: (currentFocusIdx: number, changeType: ChangeType, toBeDeleted: boolean) => void;
    export let moveNote: (oldIdx: number, newIdx: number) => void;
    export let deleteSavedNote: (noteId: number, idx: number) => void;
    export let deleteUnsavedNote: (idx: number) => void;

    let node: HTMLElement;
    let timeout: number | undefined;

    $: if (node && focusNoteId === note.id) {
        forceFocus();
        node.scrollIntoView({block: "center"});
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

    async function onFocusLostHandler() {
        if (timeout) {
            clearTimeout(timeout);
        }

        if (noteCanBeSaved()) {
            await saveNote();
        } else if (!noteCanBeSaved() && note.id === -1) {
            deleteUnsavedNote(idx);
        } else {
            deleteSavedNote(note.id, idx);
        }
    }

    function debounce(callback: () => void, wait: number) {
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

    function getLabelText(label: number, labelType: LabelType): string {
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
                    deleteSavedNote(note.id, idx);
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
                if (event.ctrlKey) {
                    event.preventDefault();
                    changeIndents(-1);
                }
                return;
            case "ArrowRight":
                if (event.ctrlKey) {
                    event.preventDefault();
                    changeIndents(1);
                }
                return;
        }
    }
</script>

{#if !viewMode.isSortable && note.isPositioned && note.label && 
        theme.noteThemes?.[note.indents]?.label !== undefined}
    <div class="label">
        {getLabelText(note.label, theme.noteThemes[note.indents].label)}.
    </div>
{/if}
{#if collectionView.editModeId === 2}
    <div class="noteContent"
        contenteditable="true"
        placeholder="Empty notes are not saved"
        bind:this={node}
        bind:innerHTML={note.content}
        on:keydown={freeEditKeyHandler}
        on:focusout={() => onFocusLostHandler()}
        on:focus={() => focusNoteId = null}
        on:keyup={() => {
                debounce(async () => await saveNote(), 4000);
                node.scrollIntoView({block: "nearest", behavior: "auto"});
            }}>
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
        flex: 1;
        border-radius: 4px;
        background-color: var(--textfieldColor);
        padding: 0.5rem 0.75rem;
        margin: 0.5rem 0;
        color: var(--fontColor);
        line-height: 1.84rem;
        font-size: 1.10rem;
        scroll-margin: 1.0rem;
    }

    [contenteditable=true]:empty:before {
        content:attr(placeholder);
        color: grey;
        user-select: none;
        cursor: text;
    }

    .label {
        width: 60px;
        color: var(--fontColor);
        text-align: center;
    }
</style>
