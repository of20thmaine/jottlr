import { Store } from "tauri-plugin-store-api";

const store = new Store(".settings.dat");

export async function SetDefaultCollection(collectionId: number) {
    store.set("default-collection", collectionId);
}

export async function GetDefaultCollection() {
    return store.get("default-collection");
}

export async function SetColorModeIsDark(isDarkMode: boolean) {
    return store.set("color-mode", isDarkMode);
}

export async function GetColorModeIsDark() {
    return store.get("color-mode");
}

export async function SetCollectionView(collectionView: CollectionView) {
    store.set("collection-views-" + collectionView.id, collectionView);
}

export async function GetCollectionView(collectionId: number): Promise<CollectionView | null> {
    return await store.get("collection-views-" + collectionId) as CollectionView | null;
}

export async function SetPageWidth(pageWidth: number) {
    return store.set("page-width", pageWidth);
}

export async function GetPageWidth(): Promise<number | null> {
    return await store.get("page-width");
}

export async function GetThemeList(): Promise<Theme[]> {
    let themes: Theme[] | null = await store.get("theme-list");
    if (!themes) {
        return SetThemeList(DefaultThemeList)
            .then(() => {return store.get("theme-list") as Promise<Theme[]>} );
    }
    return themes;
}

export async function GetUserThemeList(): Promise<Theme[] | null> {
    let themes: Theme[] | null = await store.get("theme-list");
    let userThemes = [];
    if (themes) {
        for (let theme of themes) {
            if (!theme.system) {
                userThemes.push(theme);
            }
        }
    }
    if (userThemes.length > 0) {
        return userThemes;
    }
    return null;
}

export async function SetThemeList(themeList: Theme[]) {
    store.set("theme-list", themeList);
}

export const enum LabelType {
    RomanCaps,
    AlphabetCaps,
    Numerals,
    AlphabetLowers,
    RomanLowers,
    Disc,
    Circle,
    Square,
    Arrow,
    Diamond,
    Caret
}

export const Labels: Label[] = [
    {name: "Bullets", value: LabelType.Disc, demo: '&#9679;, &#9679;'},
    {name: "Squares", value: LabelType.Square, demo: '&#9632;, &#9632;'},
    {name: "Circles", value: LabelType.Circle, demo: '&#9675;, &#9675;'},
    {name: "Arrows", value: LabelType.Arrow, demo: '&rarr;, &rarr;'},
    {name: "Diamonds", value: LabelType.Diamond, demo: '&#9670;, &#9670;'},
    {name: "Carets", value: LabelType.Caret, demo: '&#9655;, &#9655;'},
    {name: "Roman Numerals (Uppercase)", value: LabelType.RomanCaps, demo: "I, II"},
    {name: "Roman Numerals (Lowercase)", value: LabelType.RomanLowers, demo: "i, ii"},
    {name: "Alphabet (Uppercase)", value: LabelType.AlphabetCaps, demo: "A, B"},
    {name: "Alphabet (Lowercase)", value: LabelType.AlphabetLowers, demo: "a, b"},
    {name: "Numbered", value: LabelType.Numerals, demo: "1, 2"}
];

export const enum SortType {
    Date_Added_Asc,
    Date_Added_Dsc,
    Date_Modified_Asc,
    Date_Modified_Dsc,
}

export const enum ChangeType {
    Enter,
    ArrowDown,
    ArrowUp,
    AfterDelete
}

export const enum ChangeOption {
    Positional,
    Collection
}

export const EditModes: EditMode[] = [
    {id: 1, name: 'Append', class: 'append', ico: 'bi bi-plus'},
    {id: 2, name: 'Free-Edit', class: 'editing', ico: 'bi bi-pen sIco'},
    {id: 3, name: 'Read-Only', class: 'readOnly', ico: 'bi bi-lock sIco'}
];

export const DefaultThemeList: Theme[] = [
    {
        id: 1,
        system: true,
        name: "Bulleted List",
        maxIndents: 6,
        default: {
            marginLeft: 16,
            label: {name: "Bullets", value: LabelType.Disc, demo: '<i class="bi bi-circle-fill"></i>, <i class="bi bi-circle-fill"></i>'},
        }
    },
    {
        id: 2,
        system: true,
        name: "Ordered List",
        maxIndents: 6,
        default: {
            marginLeft: 32
        },
        noteThemes: [
            {
                label: {name: "Roman Numerals (Uppercase)", value: LabelType.RomanCaps, demo: "I, II"}
            },
            {
                label: {name: "Alphabet (Uppercase)", value: LabelType.AlphabetCaps, demo: "A, B"}
            },
            {
                label: {name: "Numbered", value: LabelType.Numerals, demo: "1, 2"}
            },
            {
                label: {name: "Roman Numerals (Lowercase)", value: LabelType.RomanLowers, demo: "i, ii"}
            },
            {
                label: {name: "Alphabet (Lowercase)", value: LabelType.AlphabetLowers, demo: "a, b"}
            },
            {
                label: {name: "Bullets", value: LabelType.Disc, demo: '<i class="bi bi-circle-fill"></i>, <i class="bi bi-circle-fill"></i>'},
            },
        ]
    }
];

export const DefaultViewModes: ViewModeCategory[] = [
    {
        id: 1,
        name: "Date Added:",
        ico: "bi bi-calendar3",
        options: [
            {
                id: 1,
                name: "Old to New",
                ico: "bi bi-sort-numeric-down",
                isSortable: true,
                sort: SortType.Date_Added_Asc
            },
            {
                id: 2,
                name: "New to Old",
                ico: "bi bi-sort-numeric-up-alt",
                isSortable: true,
                sort: SortType.Date_Added_Dsc
            }
        ]
    },
    {
        id: 2,
        name: "Date Modified:",
        ico: "bi bi-calendar3",
        options: [
            {
                id: 3,
                name: "Old to New",
                ico: "bi bi-sort-numeric-down",
                isSortable: true,
                sort: SortType.Date_Modified_Asc
            },
            {
                id: 4,
                name: "New to Old",
                ico: "bi bi-sort-numeric-up-alt",
                isSortable: true,
                sort: SortType.Date_Modified_Dsc
            }
        ]
    },
    {
        id: 3,
        name: "Positional:",
        ico: "bi bi-list-ol",
        options: []
    }
];
