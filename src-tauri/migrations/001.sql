-- Initial Jottlr Migration

-- Create Table Notes
CREATE TABLE "notes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "content" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),
    "updated_at" DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),
    "collection_id" INTEGER NOT NULL,
    CONSTRAINT "notes_collections_fkey"
        FOREIGN KEY ("collection_id")
        REFERENCES "collections" ("id") 
        ON DELETE CASCADE
);

-- Create Table Collections
CREATE TABLE "collections" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT UNIQUE, --Unique neccesary?
    "created_at" DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),
    "last_open" DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),
    "favorite" BOOLEAN NOT NULL DEFAULT 0
);

-- Create Table Positionals
CREATE TABLE "positionals" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),
    "last_open" DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),
    "collection_id" INTEGER NOT NULL,
    "is_subset" BOOLEAN NOT NULL DEFAULT 0,
    CONSTRAINT "positionals_collections_fkey"
        FOREIGN KEY ("collection_id")
        REFERENCES "collections" ("id") 
        ON DELETE CASCADE
);

-- Create Table Positioned Notes
CREATE TABLE "positioned_notes" (
    "positional_id" INTEGER NOT NULL,
    "note_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "indents" INTEGER NOT NULL,
    PRIMARY KEY ("positional_id", "note_id"),
    CONSTRAINT "positionednotes_positionals_fkey"
        FOREIGN KEY ("positional_id")
        REFERENCES "positionals" ("id") 
        ON DELETE CASCADE,
    CONSTRAINT "positionednotes_notes_fkey"
        FOREIGN KEY ("note_id")
        REFERENCES "notes" ("id") 
        ON DELETE CASCADE
); -- Making position part of PK adds excessive complexity :(

INSERT INTO collections (name) VALUES ("Jottlr");
