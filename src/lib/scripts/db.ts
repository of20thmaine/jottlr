import Database, { type QueryResult } from "tauri-plugin-sql-api";
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
