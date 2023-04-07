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
    Check
}

export const enum SortType {
    Date_Added_Asc,
    Date_Added_Dsc,
    Date_Modified_Asc,
    Date_Modified_Dsc,
}

export const enum ChangeType {
    Enter,
    ArrowDown,
    ArrowUp
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
            label: LabelType.Disc
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
                label: LabelType.RomanCaps
            },
            {
                label: LabelType.RomanCaps
            },
            {
                label: LabelType.RomanCaps
            },
            {
                label: LabelType.RomanCaps
            },
            {
                label: LabelType.RomanCaps
            },
            {
                label: LabelType.RomanCaps
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
