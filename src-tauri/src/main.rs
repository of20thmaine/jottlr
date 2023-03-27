#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use tauri::Manager;
use tauri_plugin_sql::{Migration, MigrationKind};
use window_shadows::set_shadow;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let window = app.get_window("main").unwrap();
            set_shadow(&window, true).expect("Unsupported platform!");
            Ok(())
        })
        .plugin(tauri_plugin_store::Builder::default().build())
        .plugin(tauri_plugin_sql::Builder::default()
            .add_migrations("sqlite:notes.db", get_migrations())
            .build())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

fn get_migrations() -> Vec<Migration> {
    let mut migrations = Vec::new();
    
    migrations.push(Migration {
        version: 1,
        description: "Initial DB implementation.",
        sql: include_str!("../migrations/001.sql"),
        kind: MigrationKind::Up
    });

    migrations
}
