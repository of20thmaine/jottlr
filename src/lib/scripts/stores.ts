import { writable } from "svelte/store";

export const WindowTitle = writable<string>("");

export const ColorModeIsDark = writable<boolean>(true);

export const ShowCreateCollection = writable<boolean>(false);

export const ThemeEditorThemeId = writable<number>();

export const OpenCollection = writable<Collection>();
