# Jottlr — Claude Code Context

## First: Read the Plan
Before starting any work, read `JOTTLR_DEVELOPMENT_PLAN.md` in this directory. It contains the full architecture, data models, phased prompts, testing strategy, and design principles for this project.

## Project Overview
Jottlr is a menu-bar-only macOS app (SwiftUI + SwiftData) for quick-capturing ideas and organizing them into themed markdown files.

## Key Conventions
- **Pure SwiftUI + SwiftData** — no UIKit. AppKit only via NSViewRepresentable where SwiftUI is insufficient (e.g., the rich text editor).
- **CloudKit-ready from day one** — all @Model properties must have default values, all relationships must be optional, never use @Attribute(.unique), never use .deny delete rules.
- **LSUIElement = YES** — no Dock icon. Menu bar only.
- **Tests alongside features** — every new service or helper gets tests in the JottlrTests target using in-memory ModelContainers for SwiftData tests.
- **Apple HIG** — use SF Symbols, system colors, system fonts, native controls. The app should look like Apple built it.
- **Minimal dependencies** — only KeyboardShortcuts and swift-markdown. Everything else is Apple-native.

## Code Style
- Use `@Observable` (not the older `ObservableObject`/`@Published` pattern)
- Use `@Query` for SwiftData fetches in views
- Use `@Environment(\.modelContext)` for inserts/deletes
- Prefer `guard let` for early exits over nested `if let`
- Use Swift concurrency (`async/await`) over callbacks where applicable
- Group files into: Models/, Views/, ViewModels/, Services/, Utilities/

## When Fixing Errors
If I paste Xcode build errors, fix them directly. Don't rewrite unrelated code — make minimal targeted fixes.

## Version Control
- Do NOT run git commands unless I explicitly ask you to.
- Keep changes scoped to the current task — don't refactor unrelated files.
- If you need to rename or move files, mention it so I can review before committing.
