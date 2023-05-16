import { goto } from '$app/navigation';
import { OpenCollection, ThemeEditorThemeId } from "$lib/scripts/stores";

export function gotoCollection(collection: Collection) {
    OpenCollection.set(collection);
    goto("collection");
}

export function gotoThemeEditor(themeId: number) {
    ThemeEditorThemeId.set(themeId);
    goto("themeeditor");
}

export function ClickOutside(node: HTMLElement) {
    const clickHandler = (event: Event) => {
        if (!(event.target instanceof HTMLElement && node.contains(event.target))) {
            node.dispatchEvent(new CustomEvent("outclick"));
            event.stopPropagation();
        }
    }
    
    document.addEventListener("click", clickHandler, true);

    return {
        destroy() {
            document.removeEventListener("click", clickHandler, true);
        }
    };
}

export function ApplyNoteStyle(node: HTMLElement, note: Note, theme: Theme) {
    if (!note.isPositioned) return;
    if (note.indents > theme.maxIndents) return;

    if (theme.noteThemes?.[note.indents]?.fontSize) {
        node.style.fontSize = theme.noteThemes[note.indents].fontSize + "px";
    } else if (theme.default?.fontSize) {
        node.style.fontSize = theme.default.fontSize + "px";
    } else {
        node.style.fontSize = "1.10rem";
    }

    if (theme.noteThemes?.[note.indents]?.fontWeight) {
        node.style.fontWeight = theme.noteThemes[note.indents].fontWeight!.value;
    } else if (theme.default?.fontWeight) {
        node.style.fontWeight = theme.default.fontWeight.value;
    } else {
        node.style.fontWeight = "400";
    }

    if (theme.noteThemes?.[note.indents]?.fontColor) {
        node.style.color = theme.noteThemes[note.indents].fontColor!;
    } else if (theme.default?.fontColor) {
        node.style.color = theme.default.fontColor;
    } else {
        node.style.color = "var(--fontColor)";
    }

    if (theme.noteThemes?.[note.indents]?.bubbleColor) {
        node.style.backgroundColor = theme.noteThemes[note.indents].bubbleColor!;
    } else if (theme.default?.bubbleColor) {
        node.style.backgroundColor = theme.default.bubbleColor;
    } else {
        node.style.backgroundColor = "var(--textfieldColor)";
    }
}

export function ApplyLabelStyle(node: HTMLElement, note: Note, theme: Theme) {
    if (!note.isPositioned || (!theme.default?.label && !theme.noteThemes?.[note.indents]?.label)) return;
    if (note.indents > theme.maxIndents) return;

    if (theme.noteThemes?.[note.indents]?.labelTheme?.fontSize) {
        node.style.fontSize = theme.noteThemes[note.indents].labelTheme!.fontSize! + "px";
    } else if (theme.default?.labelTheme?.fontSize) {
        node.style.fontSize = theme.default.labelTheme.fontSize + "px";
    } else {
        node.style.fontSize = "1.10rem";
    }

    if (theme.noteThemes?.[note.indents]?.labelTheme?.fontWeight) {
        node.style.fontWeight = theme.noteThemes[note.indents].labelTheme!.fontWeight!.value;
    } else if (theme.default?.labelTheme?.fontWeight) {
        node.style.fontWeight = theme.default.labelTheme.fontWeight.value;
    } else {
        node.style.fontWeight = "400";
    }

    if (theme.noteThemes?.[note.indents]?.labelTheme?.fontColor) {
        node.style.color = theme.noteThemes[note.indents].labelTheme!.fontColor!;
    } else if (theme.default?.labelTheme?.fontColor) {
        node.style.color = theme.default.labelTheme.fontColor;
    } else {
        node.style.color = "var(--fontColor)";
    }
}
