export function ClickOutside(node: HTMLElement) {
    const clickHandler = (event: Event) => {
        if (!(event.target instanceof HTMLElement && node.contains(event.target))) {
                node.dispatchEvent(new CustomEvent("outclick"));
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
    if (!note.isPositioned) { return }

    if (theme.noteThemes?.[note.indents]?.fontSize) {
        node.style.fontSize = theme.noteThemes[note.indents].fontSize + "px";
    } else if (theme.default?.fontSize) {
        node.style.fontSize = theme.default.fontSize + "px";
    }

    if (theme.noteThemes?.[note.indents]?.fontWeight) {
        node.style.fontWeight = theme.noteThemes[note.indents].fontWeight!;
    } else if (theme.default?.fontWeight) {
        node.style.fontWeight = theme.default.fontWeight;
    }

    if (theme.noteThemes?.[note.indents]?.fontColor) {
        node.style.color = theme.noteThemes[note.indents].fontColor!;
    } else if (theme.default?.fontColor) {
        node.style.color = theme.default.fontColor;
    }

    if (theme.noteThemes?.[note.indents]?.bubbleColor) {
        node.style.backgroundColor = theme.noteThemes[note.indents].bubbleColor!;
    } else if (theme.default?.bubbleColor) {
        node.style.backgroundColor = theme.default.bubbleColor;
    }
}

export function ApplyLabelStyle(node: HTMLElement, note: Note, theme: Theme) {
    if (!note.isPositioned || (!theme.default?.label && !theme.noteThemes?.[note.indents]?.label)) { return }

    if (theme.noteThemes?.[note.indents]?.labelTheme?.fontSize) {
        node.style.fontSize = theme.noteThemes[note.indents].labelTheme!.fontSize! + "px";
    } else if (theme.default?.labelTheme?.fontSize) {
        node.style.fontSize = theme.default.labelTheme.fontSize + "px";
    }

    if (theme.noteThemes?.[note.indents]?.labelTheme?.fontWeight) {
        node.style.fontWeight = theme.noteThemes[note.indents].labelTheme!.fontWeight!;
    } else if (theme.default?.labelTheme?.fontWeight) {
        node.style.fontWeight = theme.default.labelTheme.fontWeight;
    }

    if (theme.noteThemes?.[note.indents]?.labelTheme?.fontColor) {
        node.style.color = theme.noteThemes[note.indents].labelTheme!.fontColor!;
    } else if (theme.default?.labelTheme?.fontColor) {
        node.style.color = theme.default.labelTheme.fontColor;
    }
}
