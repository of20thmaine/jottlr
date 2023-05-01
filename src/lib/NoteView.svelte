<script lang="ts">
    import { CreateNote, CreatePositionedNote, UpdateNote, UpdateNotePosition } from "$lib/scripts/db";
    import { ChangeType, LabelType } from "$lib/scripts/settings";
    import { ApplyLabelStyle, ApplyNoteStyle } from "$lib/scripts/utils";

    export let note: Note;
    export let idx: number;
    export let collectionView: CollectionView;
    export let focusNoteId: number | null;
    export let viewMode: ViewMode;
    export let theme: Theme;
    export let forceFocusChange: (currentFocusIdx: number, changeType: ChangeType, toBeDeleted: boolean) => void;
    export let moveNote: (oldIdx: number, newIdx: number) => void;
    export let deleteSavedNote: (noteId: number, idx: number) => Promise<void>;
    export let deleteUnsavedNote: (idx: number) => Promise<void>;

    let noteNode: HTMLElement;
    let labelNode: HTMLElement;
    let timeout: number | undefined;

    $: if (noteNode && focusNoteId === note.id) {
        forceFocus();
        noteNode.scrollIntoView({block: "center"});
    }

    $: if (note.isPositioned) {
        if (note.position !== idx) {
            UpdateNotePosition(collectionView.viewModeId, note.id, idx, note.indents);
            note.position = idx;
        }
    }

    $: theme, applyTheme();

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

    function applyTheme() {
        if (noteNode) {
            ApplyNoteStyle(noteNode, note, theme);
        }

        if (labelNode) {
            ApplyLabelStyle(labelNode, note, theme);

            if (note.isPositioned && note.label) {
                if (theme.noteThemes?.[note.indents]?.label?.value !== undefined) {
                    setLabelText(note.label, theme.noteThemes[note.indents].label?.value);
                } else if (theme.default?.label?.value !== undefined) {
                    setLabelText(note.label, theme.default?.label?.value);
                }
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
        range.selectNodeContents(noteNode);
        range.collapse(false);
        let sel = window.getSelection();
        sel?.removeAllRanges();
        sel?.addRange(range);
        noteNode.focus();
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

    function incrementIndent() {
        if (!note.isPositioned || note.indents+1 > theme.maxIndents) return;
        UpdateNotePosition(collectionView.viewModeId, note.id, idx, ++note.indents);
    }

    function decrementIndent() {
        if (!note.isPositioned || note.indents-1 < 0) return;
        UpdateNotePosition(collectionView.viewModeId, note.id, idx, --note.indents);
    }

    function setLabelText(label: number, labelType: LabelType) {
        switch (labelType) {
            case LabelType.RomanCaps:
                labelNode.innerHTML = romanizeLabel(label) + ".";
                return;
            case LabelType.RomanLowers:
                labelNode.innerHTML = romanizeLabel(label).toLowerCase() + ".";
                return;
            case LabelType.AlphabetCaps:
                labelNode.innerHTML = alphabetizeLabel(label) + ".";
                return;
            case LabelType.AlphabetLowers:
                labelNode.innerHTML = alphabetizeLabel(label).toLowerCase() + ".";
                return;
            case LabelType.Numerals:
                labelNode.innerHTML = label.toString() + ".";
                return;
            case LabelType.Disc:
                labelNode.innerHTML = "&#9679;";
                return;
            case LabelType.Circle:
                labelNode.innerHTML = "&#9675;";
                return;
            case LabelType.Square:
                labelNode.innerHTML = "&#9632;";
                return;
            case LabelType.Arrow:
                labelNode.innerHTML = "&rarr;";
                return;
            case LabelType.Diamond:
                labelNode.innerHTML = "&#9670;";
                return;
            case LabelType.Caret:
                labelNode.innerHTML = "&#9655;";
                return;
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
                    deleteUnsavedNote(idx).then(() => forceFocusChange(idx, ChangeType.AfterDelete, false));
                } else {
                    deleteSavedNote(note.id, idx).then(() => forceFocusChange(idx, ChangeType.AfterDelete, false));
                }
                return;
            case "Tab":
                event.preventDefault();
                if (event.shiftKey) {
                    decrementIndent();
                } else {
                    incrementIndent();
                }
                return;
            case "ArrowLeft":
                if (event.ctrlKey) {
                    event.preventDefault();
                    decrementIndent();
                }
                return;
            case "ArrowRight":
                if (event.ctrlKey) {
                    event.preventDefault();
                    incrementIndent();
                }
                return;
        }
    }
</script>

{#if !viewMode.isSortable && note.isPositioned && note.label}
    {#if note.indents > theme.maxIndents}
        <div class="label">
            <i class="bi bi-info-circle" 
                title="Note indents exceeds theme indent limit. To fix either edit the theme indent limit or unindent this note.">
            </i>
        </div>
    {:else if theme.noteThemes?.[note.indents]?.label?.value !== undefined || theme.default?.label?.value !== undefined}
        <div class="label" bind:this={labelNode} />
    {/if}
{/if}
{#if collectionView.editModeId === 2}
    <div class="noteContent"
        contenteditable="true"
        placeholder="Empty notes are not saved"
        bind:this={noteNode}
        bind:innerHTML={note.content}
        on:keydown={freeEditKeyHandler}
        on:focusout={() => onFocusLostHandler()}
        on:focus={() => focusNoteId = null}
        on:keyup={() => {
                debounce(async () => await saveNote(), 4000);
                noteNode.scrollIntoView({block: "nearest", behavior: "auto"});
            }}>
    </div>
{:else}
    <div class="noteContent"
        contenteditable="false"
        bind:this={noteNode}
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
        min-width: 42px;
        color: var(--fontColor);
        font-size: 1.10rem;
        text-align: center;
    }
</style>
