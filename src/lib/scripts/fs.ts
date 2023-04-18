import { save } from '@tauri-apps/api/dialog';
import { writeTextFile } from '@tauri-apps/api/fs';
import { ExportCollectionAsJottlr, GetCollection, GetPositional } from './db';
import { SortType } from "$lib/scripts/settings";

/**
 * The way this is going to work... ->
 * 
 * 1. Export mode will open a dialog, the export dialog. This will allow the user to choose
 * between a range of export options, initially just ".jottlr" (JSON dump) and .txt (this is
 * only for v0.1 !!!!!, its okay to heavily restrict!).
 * 
 * 2. Import mode will first open the system open file dialog, after which if a valid selection
 * is made an import mode dialog will be opened, this will include options for importing the
 * theme (if included in the file)
 * 
 */

export async function ExportToJottlr(collection: Collection, theme?: Theme): Promise<void> {
    const filePath = await save(
        { title: "Export To", filters: [{ name: "Jottlr", extensions: ["jottlr"] }] }
    );
    if (!filePath) return Promise.reject("Export requires a file to export to.");

    let saveObject = await ExportCollectionAsJottlr(collection)
    if (!saveObject) return Promise.reject("There was a problem.");

    if (theme) saveObject.theme = theme;

    return await writeTextFile(filePath, JSON.stringify(saveObject));
}


export async function ExportToTxt(collection: Collection, positional?: Positional) {
    const filePath = await save(
        { title: "Export To", filters: [{ name: "Text", extensions: ["txt"] }] }
    );
    if (!filePath) return Promise.reject("Export requires a file to export to.");
    
    let notes; 
    if (positional) {
        notes = await GetPositional(positional.id);
    } else {
        notes = await GetCollection(collection.id, SortType.Date_Added_Asc);
    }

    // This is gonna end up being a more annoying task than originally thought:
    // (assign to future self)
    notes = notes.map(item => item.content);
    notes = notes.join("\n\n");
    notes = notes.replace( /(<([^>]+)>)/ig, '');

    return await writeTextFile(filePath, notes);
}

export const enum ExportType {
    Jottlr,
    Text
}

export const exportOptions: ExportOption[] = [
    {name: "Jottlr (.jottlr)", type: ExportType.Jottlr},
    {name: "Text (.txt)", type: ExportType.Text}
];
