import Database, { type QueryResult } from "tauri-plugin-sql-api";
import { getVersion } from '@tauri-apps/api/app';
import { SortType } from "$lib/scripts/settings";

const db = await Database.load("sqlite:notes.db");

export async function CreateNote(content: string, collection_id: number): Promise<QueryResult> {
    return await db.execute(
        "INSERT INTO notes (content, collection_id) VALUES ($1, $2)",
        [content, collection_id]
    );
}

export async function CreateCollection(name: string): Promise<QueryResult> {
    return await db.execute(
        "INSERT INTO collections (name) VALUES ($1)",
        [name]
    );
}

export async function UpdateNote(id: number, content: string): Promise<QueryResult> {
    return await db.execute(
        "UPDATE notes SET content = $1, updated_at = (datetime(CURRENT_TIMESTAMP, 'localtime')) WHERE id = $2",
        [content, id]
    );
}

export async function DeleteNote(id: number): Promise<QueryResult> {
    return await db.execute(
        "DELETE FROM notes WHERE id = $1",
        [id]
    );
}

export async function GetCollection(collection_id: number, sort: SortType): Promise<Note[]> {
    return await db.select(
        "SELECT *, 0 as isPositioned FROM notes WHERE collection_id = $1 ORDER BY $2",
        [collection_id, getOrderByStr(sort)]
    );
}

export async function GetCollectionList(): Promise<Collection[]> {
    return await db.select(
        "SELECT * FROM collections"
    );
}

export async function GetCollections(): Promise<CollectionSelection[]> {
    return await db.select(
        "SELECT id, name, (SELECT COUNT(*) FROM notes WHERE notes.collection_id = collections.id) " +
        "note_count, last_open, favorite FROM collections ORDER BY last_open DESC"
    );
}

export async function GetLastOpenCollection(): Promise<Collection[]> {
    return await db.select(
        "SELECT id, name, MAX(last_open) FROM collections"
    );
}

export async function GetFavorites(): Promise<CollectionSelection[]> {
    return await db.select(
        "SELECT id, name, (SELECT COUNT(*) FROM notes WHERE notes.collection_id = collections.id) " +
        "note_count, last_open, favorite FROM collections WHERE favorite = 1 ORDER BY last_open DESC"
    );
}

export async function SetCollectionFavorite(collection_id: number, isFavorite: boolean): Promise<QueryResult> {
    let value = isFavorite ? 1 : 0;
    return await db.execute(
        "UPDATE collections SET favorite = $1 WHERE id = $2",
        [value, collection_id]
    );
}

export async function UpdateCollectionLastOpen(collection_id: number): Promise<QueryResult> {
    return await db.execute(
        "UPDATE collections SET last_open = (datetime(CURRENT_TIMESTAMP, 'localtime')) WHERE id = $1",
        [collection_id]
    );
}

export async function CreatePositional(name: string, collection_id: number): Promise<QueryResult> {
    return await db.execute(
        "INSERT INTO positionals (name, collection_id) VALUES ($1, $2)",
        [name, collection_id]
    );
}

export async function GetCollectionsPositionals(collection_id: number): Promise<Positional[]> {
    return await db.select(
        "SELECT id, name, created_at, last_open FROM positionals WHERE collection_id = $1",
        [collection_id]
    );
}

export async function GetPositional(positional_id: number): Promise<PositionedNote[]> {
    return await db.select(
        "SELECT *, 1 as isPositioned FROM notes INNER JOIN positioned_notes ON notes.id = " +
        "positioned_notes.note_id WHERE positioned_notes.positional_id = $1 ORDER BY position",
        [positional_id]
    );
}

export async function CreatePositionedNote(positionId: number, noteId: number, position: number, indents: number) {
    return await db.execute(
        "INSERT INTO positioned_notes (positional_id, note_id, position, indents) VALUES ($1, $2, $3, $4)",
        [positionId, noteId, position, indents]
    );
}

export async function UpdateNotePosition(positionId: number, noteId: number, position: number, indents: number) {
    return await db.execute(
        "UPDATE positioned_notes SET position = $1, indents = $2 WHERE positional_id = $3 AND note_id = $4",
        [position, indents, positionId, noteId]
    );
}

export async function DeleteFromPositionedNotes(positionId: number, noteId: number) {
    return await db.execute(
        "DELETE FROM positioned_notes WHERE positional_id = $1 AND note_id = $2",
        [positionId, noteId]
    );
}

export async function DeleteCollection(collectionId: number) {
    return await db.execute(
        "DELETE FROM collections WHERE id = $1",
        [collectionId]
    );
}

export async function DeletePositional(positionalId: number, deleteNotes: boolean) {
    if (deleteNotes) {
        let notes = await GetPositional(positionalId);
        for (let note of notes) {
            DeleteNote(note.id);
        }
    }
    return await db.execute(
        "DELETE FROM positionals WHERE id = $1",
        [positionalId]
    );
}

export async function ExportCollectionAsJottlr(collection: Collection): Promise<JottlrSave> {
    const positionals: SavePositional[] = await GetSavePositionals(collection.id);
    return {
        version: await getVersion(),
        collection: collection as SaveCollection,
        notes: await GetSaveNotes(collection.id),
        positionals: positionals,
        positionedNotes: await GetSavePositionedNotes(positionals)
    };
}

async function GetSaveNotes(collection_id: number): Promise<SaveNote[]> {
    return await db.select(
        "SELECT * FROM notes WHERE collection_id = $1",
        [collection_id]
    );
}

async function GetSavePositionals(collection_id: number): Promise<SavePositional[]> {
    return await db.select(
        "SELECT id, name, created_at FROM positionals WHERE collection_id = $1",
        [collection_id]
    );
}

async function GetSavePositionedNotes(positionals: SavePositional[]): Promise<SavePositionedNote[]> {
    let notes: SavePositionedNote[] = [];
    for (let positional of positionals) {
        notes.push(...await GetPositionsSavedNotes(positional));
    }
    return notes;
}

async function GetPositionsSavedNotes(positional: SavePositional): Promise<SavePositionedNote[]> {
    return await db.select(
        "SELECT * FROM positioned_notes WHERE positional_id = $1",
        [positional.id]
    );
}

export async function ImportCollectionFromJottlr(data: JottlrSave): Promise<Collection> {
    if (data.version !== await getVersion()) {
        throw new Error("Import version does not match app version.");
    }
    
    let noteIdMap = new Map<number, number>();
    let positionalIdMap = new Map<number, number>();

    let collection = await CreateCollection(data.collection.name);

    for (let note of data.notes) {
        let saveNote = await CreateNote(note.content, collection.lastInsertId);
        noteIdMap.set(note.id, saveNote.lastInsertId);
    }

    for (let positional of data.positionals) {
        let savePositional = await CreatePositional(positional.name, collection.lastInsertId);
        positionalIdMap.set(positional.id, savePositional.lastInsertId);
    }

    for (let note of data.positionedNotes) {
        if (positionalIdMap.has(note.positional_id) && noteIdMap.has(note.note_id)) {
            CreatePositionedNote(
                positionalIdMap.get(note.positional_id)!,
                noteIdMap.get(note.note_id)!, 
                note.position,
                note.indents
            );
        }
    }
    return { id: collection.lastInsertId, name: data.collection.name };
}

/**
 * Returns query substring for note sorting.
 * @param sortType 
 * @returns String which goes in "ORDER BY" part of query
 */
function getOrderByStr(sortType: SortType): string {
    switch (sortType) {
        case SortType.Date_Added_Asc:
            return "created_at ASC";
        case SortType.Date_Added_Dsc:
            return "created_at DSC";
        case SortType.Date_Modified_Asc:
            return "updated_at ASC";
        case SortType.Date_Modified_Dsc:
            return "updated_at DSC";
    }
}
