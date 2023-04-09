interface StandardNote {
    id: number;
    content: string;
    created_at: string;
    updated_at: string;
    isPositioned: false;
}

interface PositionedNote {
    id: number;
    content: string;
    created_at: string;
    updated_at: string;
    position: number;
    indents: number;
    isPositioned: true;
    label?: number;
}

type Note = StandardNote | PositionedNote;

interface Collection {
    id: number;
    name: string;
}

interface CollectionView {
    id: number;
    name: string;
    editModeId: number;
    viewCategoryId: number;
    viewModeId: number;
    themeId: number;
}

interface CollectionSelection {
    id: number;
    name: string;
    note_count: number;
    last_open: string;
    favorite: boolean;
}

interface EditMode {
    id: number;
    name: string;
    class: string;
    ico: string;
}

interface Positional {
    id: number;
    name: string;
    created_at: string;
    last_open: string;
    isSortable: false;
}

interface Sortable {
    id: number;
    name: string;
    sort: SortType;
    ico: string;
    isSortable: true;
}

interface FontWeight {
    name: string;
    value: string;
}

interface Label {
    name: string;
    value: LabelType;
}

type ViewMode = Sortable | Positional;

interface ViewModeCategory {
    id: number;
    name: string;
    ico: string;
    options: ViewMode[];
}

declare namespace svelteHTML {
    interface HTMLAttributes<T> {
        'on:outclick'?: (event: any) => any;
    }
}

interface Theme {
    id: number;
    system: boolean;
    name: string;
    maxIndents: number;
    default?: NoteTheme;
    noteThemes?: NoteTheme[];
}

interface NoteTheme {
    marginLeft?: number;
    fontSize?: number;
    fontWeight?: FontWeight;
    fontColor?: string;
    bubbleColor?: string;
    label?: Label;
    labelTheme?: LabelTheme;
}

interface LabelTheme {
    fontSize?: number;
    fontWeight?: FontWeight;
    fontColor?: string;
}
