declare namespace svelteHTML {
    interface HTMLAttributes<T> {
        'on:outclick'?: (event: any) => any;
    }
}

interface StandardNote {
    id: number;
    content: string;
    created_at: string;
    updated_at: string;
    isPositioned: false;
    selected?: boolean;
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
    selected?: boolean;
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
    last_open: string | null;
    favorite: boolean;
}

interface EditMode {
    id: number;
    name: string;
    class: string;
    ico: string;
}

interface ViewModeCategory {
    id: number;
    name: string;
    ico: string;
    options: ViewMode[];
}

interface Positional {
    id: number;
    name: string;
    created_at: string;
    last_open: string | null;
    isSortable: false;
}

interface Sortable {
    id: number;
    name: string;
    sort: SortType;
    ico: string;
    isSortable: true;
}

type ViewMode = Sortable | Positional;

interface FontWeight {
    name: string;
    value: string;
}

interface Label {
    name: string;
    value: LabelType;
    demo: string;
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

interface ExportOption {
    name: string;
    type: ExportType;
}

interface JottlrSave {
    version: string;
    collection: SaveCollection;
    notes: SaveNote[];
    positionals: SavePositional[];
    positionedNotes: SavePositionedNote[];
    theme?: Theme;
}

interface SaveCollection {
    name: string;
}

interface SaveNote {
    id: number;
    content: string;
    created_at: string;
    updated_at: string;
}

interface SavePositional {
    id: number;
    name: string;
    created_at: string;
}

interface SavePositionedNote {
    positional_id: number;
    note_id: number;
    position: number;
    indents: number;
}

interface ChangeObject {
    collection: Collection;
    viewMode: ViewMode;
}
