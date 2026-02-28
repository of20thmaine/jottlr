# Jottlr — Complete Development Plan

## Table of Contents

1. [Vision & Architecture](#1-vision--architecture)
2. [Data Models (SwiftData)](#2-data-models-swiftdata)
3. [Phase 1: Jotlog Core](#3-phase-1-jotlog-core)
4. [Phase 2: File Sidebar & Basic Editor](#4-phase-2-file-sidebar--basic-editor)
5. [Phase 3: WYSIWYG Markdown Rendering](#5-phase-3-wysiwyg-markdown-rendering)
6. [Phase 4: List Editing Power Features](#6-phase-4-list-editing-power-features)
7. [Phase 5: Theming System](#7-phase-5-theming-system)
8. [Phase 6: CloudKit Preparation](#8-phase-6-cloudkit-preparation)
9. [Testing Strategy](#9-testing-strategy)
10. [Swift/SwiftUI Concepts for Java/C#/Web Developers](#10-swiftswiftui-concepts-for-javacweb-developers)
11. [Claude Code Workflow Guide](#11-claude-code-workflow-guide)
12. [Project Structure](#12-project-structure)
13. [Dependencies](#13-dependencies)
14. [Design Principles](#14-design-principles)

---

## 1. Vision & Architecture

Jottlr is a menu-bar-only macOS app for capturing fleeting ideas instantly and organizing them into beautifully themed markdown files.

### Three Pillars

```
┌─────────────────────────────────────────────────────┐
│                     JOTTLR                          │
│                                                     │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────┐ │
│  │  JOTLOG   │   │   MARKDOWN   │   │   THEMING   │ │
│  │           │   │    EDITOR    │   │   SYSTEM    │ │
│  │ Quick     │──>│              │   │             │ │
│  │ Capture   │   │ WYSIWYG     │<──│ Fonts,      │ │
│  │ + History │   │ + File Tree  │   │ Colors,     │ │
│  │           │   │ + Lists      │   │ List Styles │ │
│  └──────────┘   └──────────────┘   └─────────────┘ │
│        │                 │                │         │
│        └─────────┬───────┘                │         │
│            ┌─────┴──────┐                 │         │
│            │  SwiftData  │<───────────────┘         │
│            │ (Persistence)│                          │
│            └─────────────┘                          │
└─────────────────────────────────────────────────────┘
```

### App Lifecycle

Jottlr lives exclusively in the macOS menu bar (the row of small icons near your clock). It has no Dock icon and no traditional app window. The user interacts with it in two ways:

1. **Click the menu bar icon** → opens a popover/window with the full app UI
2. **Press a global hotkey** (e.g., ⌘⇧J) → opens a quick-capture input field that floats over whatever app they're using

Think of it like Spotlight (⌘Space) but for jotting down ideas.

### Key Architectural Decisions

- **Pure SwiftUI + SwiftData** — no UIKit/AppKit bridges unless absolutely necessary
- **Menu bar app using `MenuBarExtra`** — Apple's native SwiftUI scene type for menu bar apps
- **Global hotkey via `KeyboardShortcuts` package** — the most maintained Swift package for system-wide keyboard shortcuts
- **All models CloudKit-compatible from day one** — all properties have defaults, all relationships are optional, no `@Attribute(.unique)`
- **`LSUIElement = YES`** in Info.plist — hides the app from the Dock and app switcher
- **NavigationSplitView** for the editor — gives us the native Apple sidebar + content + detail pattern

---

## 2. Data Models (SwiftData)

These models are designed to be CloudKit-compatible from the start. In Java/C# terms, think of `@Model` as an `@Entity` annotation — it tells the framework to persist this class automatically.

### CloudKit Compatibility Rules (Baked In From Day One)

- ✅ All properties must have default values OR be optional
- ✅ All relationships must be optional
- ❌ Never use `@Attribute(.unique)` — CloudKit doesn't support unique constraints
- ❌ Never use `.deny` delete rules on relationships
- ✅ Use only simple types: String, Int, Double, Bool, Date, Data, UUID

### Jotting Model

```swift
import SwiftData
import Foundation

@Model
final class Jotting {
    var id: UUID = UUID()
    var content: String = ""
    var createdAt: Date = Date()
    var tags: [String] = []        // Stored as JSON-encoded array
    var isPinned: Bool = false

    // Optional relationship — CloudKit requires this
    @Relationship(deleteRule: .nullify)
    var copies: [JottingCopy]? = []

    init(content: String, tags: [String] = []) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.tags = tags
        self.isPinned = false
    }
}
```

**Java/C# analogy:** This is like a JPA `@Entity` class or an EF Core model. The `@Model` macro auto-generates all the persistence boilerplate. SwiftData observes property changes automatically — no need for `PropertyChanged` events or `@Published` wrappers.

### JottingCopy Model

Tracks when a jotting has been copied into a markdown file. The original jotting is never modified.

```swift
@Model
final class JottingCopy {
    var id: UUID = UUID()
    var copiedAt: Date = Date()
    var destinationFilePath: String = ""

    @Relationship(deleteRule: .nullify)
    var originalJotting: Jotting?

    init(destinationFilePath: String, originalJotting: Jotting?) {
        self.id = UUID()
        self.copiedAt = Date()
        self.destinationFilePath = destinationFilePath
        self.originalJotting = originalJotting
    }
}
```

### Theme Model

```swift
@Model
final class Theme {
    var id: UUID = UUID()
    var name: String = "Default"
    var isBuiltIn: Bool = false
    var createdAt: Date = Date()

    // Typography
    var headingFontName: String = "SF Pro Display"
    var bodyFontName: String = "SF Pro Text"
    var monoFontName: String = "SF Mono"
    var baseFontSize: Double = 14.0

    // Colors stored as hex strings (CloudKit-safe)
    var backgroundColorHex: String = "#FFFFFF"
    var textColorHex: String = "#1D1D1F"
    var accentColorHex: String = "#007AFF"
    var headingColorHex: String = "#1D1D1F"

    // List styling — stored as JSON-encoded data
    // Each level can have: marker type, indent, color, font size
    var listStyleJSON: String = "[]"

    // Spacing
    var paragraphSpacing: Double = 12.0
    var lineHeight: Double = 1.5

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
```

### ListLevelStyle (Not persisted — decoded from Theme.listStyleJSON)

```swift
struct ListLevelStyle: Codable {
    var level: Int                    // 0, 1, 2, 3...
    var markerType: ListMarkerType   // bullet, number, checkbox, dash, arrow, etc.
    var markerSymbol: String?        // Custom symbol if markerType is .custom
    var indentPoints: Double         // Points of indent per level
    var markerColorHex: String       // Color of the bullet/number
    var textColorHex: String?        // Override text color for this level (nil = inherit)
    var fontSizeOffset: Double       // +/- from base size
    var marginTop: Double            // Space above this level
    var marginBottom: Double         // Space below
    var paddingLeading: Double       // Space between marker and text
}

enum ListMarkerType: String, Codable {
    case bullet         // •
    case dash           // —
    case arrow          // →
    case diamond        // ◆
    case circle         // ○
    case square         // ■
    case checkboxEmpty  // ☐
    case checkboxFilled // ☑
    case decimal        // 1. 2. 3.
    case alpha          // a. b. c.
    case roman          // i. ii. iii.
    case custom         // User-defined symbol
}
```

---

## 3. Phase 1: Jotlog Core

**Goal:** A working menu bar app where you press a hotkey, type an idea, hit Enter, and it's saved. You can view your history as a scrollable chat-like timeline.

### What You'll Build

1. Menu bar icon using `MenuBarExtra` with `.menuBarExtraStyle(.window)`
2. Global hotkey (⌘⇧J default) using the `KeyboardShortcuts` Swift package
3. Quick-capture floating input field
4. SwiftData persistence for jottings
5. Chat-history-style scrollable timeline view
6. Basic search/filter for jottings

### Key SwiftUI Concepts Introduced

| Concept | Web/Java/C# Equivalent |
|---------|----------------------|
| `@main struct JottlrApp: App` | `public static void main()` / entry point |
| `MenuBarExtra` scene | A system tray icon in Windows, or a Chrome extension popup |
| `@State` | React's `useState` or a local ViewModel property |
| `@Query` (SwiftData) | A live LINQ query or a React Query hook — auto-updates the UI |
| `@Environment(\.modelContext)` | Dependency injection — like `@Inject` in Spring or `IServiceProvider` in .NET |
| `ScrollView` + `LazyVStack` | A virtualized list (like React's windowed list) |
| `.onSubmit` modifier | `onSubmit` in a React form |
| `TextField` | `<input>` in HTML |

### Claude Code Prompts (Use These In Order)

**Prompt 1 — Project Setup & Menu Bar Shell**

```
I'm building a macOS menu bar app called Jottlr using SwiftUI and SwiftData.

Set up the following:

1. Modify JottlrApp.swift to use MenuBarExtra with .menuBarExtraStyle(.window)
   instead of WindowGroup. The menu bar icon should use SF Symbol "pencil.and.scribble".

2. Set Info.plist key "Application is agent (UIElement)" to YES so the app
   has no Dock icon.

3. Create a ContentView that just shows "Jottlr" as placeholder text with
   a Quit button that calls NSApp.terminate(nil).

4. Add the KeyboardShortcuts Swift package (https://github.com/sindresorhus/KeyboardShortcuts)
   via Swift Package Manager.

5. Define a keyboard shortcut name .quickCapture with a default of ⌘⇧J.

6. Set up a listener in the app that prints "Hotkey pressed!" when triggered.

Keep the code minimal and clean. Use modern Swift concurrency patterns.
```

**Prompt 2 — SwiftData Models**

```
Add SwiftData models to the Jottlr project.

Create a Models/ folder with:

1. Jotting.swift — @Model class with properties:
   - id: UUID (default UUID())
   - content: String (default "")
   - createdAt: Date (default Date())
   - tags: [String] (default [])
   - isPinned: Bool (default false)

2. JottingCopy.swift — @Model class with:
   - id: UUID (default UUID())
   - copiedAt: Date (default Date())
   - destinationFilePath: String (default "")
   - optional relationship to Jotting (deleteRule: .nullify)

IMPORTANT: All properties must have default values and all relationships
must be optional. This is for future CloudKit compatibility.

Set up the ModelContainer in JottlrApp.swift for the Jotting schema.
```

**Prompt 3 — Quick Capture Input**

```
Create the quick capture UI for Jottlr.

Build a QuickCaptureView that:
1. Shows a TextField with placeholder "Jot something down..."
2. Has a large, clean input style — think Spotlight search bar aesthetics
3. When the user presses Enter (use .onSubmit), save a new Jotting to SwiftData
4. After saving, clear the input field and show a brief confirmation
5. Use @Environment(\.modelContext) to access SwiftData
6. Show the 3 most recent jottings below the input as a mini-preview

Make this the content of the MenuBarExtra window.
Style it to feel native macOS — use system fonts, subtle backgrounds,
appropriate padding. The window should be approximately 400pt wide.
```

**Prompt 4 — Jotlog Timeline View**

```
Create the Jotlog timeline view for Jottlr.

Build a JotlogView that:
1. Uses @Query to fetch all Jottings sorted by createdAt descending
2. Displays them in a ScrollView with LazyVStack (like a chat history)
3. Each jotting shows:
   - The content text
   - A relative timestamp (e.g., "2 hours ago", "Yesterday")
   - A subtle pin icon if isPinned
4. Group jottings by day with section headers ("Today", "Yesterday", date)
5. Add a search bar at the top that filters jottings by content
6. Right-click context menu on each jotting with: Pin/Unpin, Copy Text, Delete
7. Add a toggle in the MenuBarExtra to switch between QuickCaptureView
   and JotlogView (use a simple tab-like control at the top)

Use .searchable modifier for the search bar.
Follow Apple HIG — use system colors, SF Symbols, native controls.
```

### What To Look For In The Generated Code (Learning Moments)

After each prompt, before moving to the next, examine the code and look for these patterns:

- **`@main struct JottlrApp: App`** — This is Swift's entry point, equivalent to `public static void main()`. The `App` protocol requires a `body` property that returns one or more `Scene` objects. A `Scene` is a top-level container (window, menu bar item, settings panel).

- **`@State private var inputText = ""`** — This is exactly like React's `useState("")`. When `inputText` changes, SwiftUI re-renders only the views that read it. In C#/WPF, this would be a property with `INotifyPropertyChanged`.

- **`@Query(sort: \Jotting.createdAt, order: .reverse)`** — This is a live database query. Imagine if your LINQ query or SQL `SELECT` ran continuously and automatically updated your ListView whenever the database changed. That's `@Query`.

- **`@Environment(\.modelContext)`** — SwiftUI's dependency injection. The `modelContext` is like a Unit of Work / DbContext in Entity Framework. You use it to insert, delete, and save objects. It's injected by the framework, not created by you.

---

## 4. Phase 2: File Sidebar & Basic Editor

**Goal:** A split-view interface with a directory tree on the left and a text editor on the right. Users can browse markdown files and open them for editing.

### What You'll Build

1. `NavigationSplitView` with sidebar + detail layout
2. Directory picker using `NSOpenPanel` (the native macOS "Open Folder" dialog)
3. Recursive file tree showing `.md` files
4. Basic `TextEditor` for editing markdown source
5. File read/write using Swift's `FileManager`
6. Jotlog sidebar panel to copy jottings into the active document

### Key SwiftUI Concepts Introduced

| Concept | Web/Java/C# Equivalent |
|---------|----------------------|
| `NavigationSplitView` | A layout with `<aside>` sidebar + `<main>` content |
| `List` with `OutlineGroup` | A tree view / recursive `<ul>` with expand/collapse |
| `@Observable` class | A ViewModel in MVVM, or a MobX store |
| `FileManager` | `java.io.File` / `System.IO` / Node's `fs` |
| `NSOpenPanel` | `<input type="file">` or `JFileChooser` |
| `.fileImporter` modifier | A declarative file picker attached to a view |
| `Binding<String>` | Two-way data binding (like `v-model` in Vue) |

### Claude Code Prompts

**Prompt 5 — App Structure Refactor**

```
Refactor Jottlr to support both the menu bar quick-capture AND a full
editor window.

The app should have:
1. MenuBarExtra (already exists) — for quick capture and jotlog viewing
2. A main Window scene (WindowGroup) that opens the full editor
   - This window should open when the user clicks "Open Editor" in the
     menu bar popover
   - Use Window(id:) so we can open it programmatically with @Environment(\.openWindow)

The menu bar should remain the primary interface. The editor window is
secondary — it opens on demand.

Update the MenuBarExtra content to have three tabs/sections:
- Quick Capture (existing)
- Jotlog (existing)
- A button to open the editor window

Keep LSUIElement = YES. The Dock icon should NOT appear even when the
editor window is open. Use NSApp.setActivationPolicy(.regular) only
temporarily if needed to bring the window to front.
```

**Prompt 6 — File Sidebar**

```
Build the file sidebar for Jottlr's editor window.

Create a FileTreeView that:
1. Has an "Open Folder" button that uses NSOpenPanel to pick a directory
2. Recursively scans the directory for .md files
3. Displays them in a List with OutlineGroup for nested folders
4. Each file shows its name with a document icon (SF Symbol "doc.text")
5. Each folder shows its name with a folder icon, expandable/collapsible
6. Selecting a file loads its contents into a @Binding<String>
7. Store the selected directory path in @AppStorage so it persists

Create a FileManager helper (FileSystemService.swift) that:
- Scans directories recursively
- Reads file contents as String
- Writes String to file
- Watches for file changes using DispatchSource (so external edits appear)

Use an @Observable class as the view model (EditorViewModel).
```

**Prompt 7 — Basic Text Editor**

```
Build the basic markdown text editor for Jottlr.

Create an EditorView that:
1. Uses NavigationSplitView with:
   - Sidebar: FileTreeView (already created)
   - Detail: Text editing area
2. The text editor should use TextEditor (SwiftUI's built-in multi-line text input)
3. Show the filename in a toolbar at the top
4. Auto-save after 2 seconds of inactivity (debounce the save)
5. Show a subtle "Saving..." / "Saved" indicator
6. Support basic keyboard shortcuts: ⌘S (save), ⌘N (new file)
7. Add a sidebar toggle button in the toolbar

Also add a Jotlog panel:
- A collapsible right sidebar showing recent jottings
- Each jotting has a "Copy to Editor" button that inserts the jotting
  text at the current cursor position (or appends to end)
- When copied, create a JottingCopy record linking to the original

Use .toolbar modifier for the toolbar items.
Use the native macOS window chrome — no custom title bar.
```

### Learning Moments

- **`NavigationSplitView`** — This is Apple's way of doing the classic three-column macOS layout (like Finder, Mail, Notes). It handles responsive sizing, sidebar collapse, and toolbar integration automatically. In web terms, it's a CSS Grid layout with built-in responsive breakpoints.

- **`@Observable`** — This replaced the older `ObservableObject` protocol. It's like a MobX observable class — any property you read in a SwiftUI view automatically subscribes that view to changes. No `@Published` wrapper needed (that was the old way). Think of it as "everything is reactive by default."

- **`@AppStorage("key")`** — This is exactly like `localStorage.getItem("key")` in JavaScript, but it's also reactive. When the stored value changes, any view reading it re-renders.

---

## 5. Phase 3: WYSIWYG Markdown Rendering

**Goal:** Replace the plain TextEditor with a rich text view that renders markdown inline — bold text appears bold as you type, headings appear large, lists show real bullets, etc.

### Technical Approach

This is the most technically complex phase. There are two viable approaches:

**Option A: NSTextView with AttributedString (Recommended)**
- Wrap AppKit's `NSTextView` in a SwiftUI `NSViewRepresentable`
- Parse markdown to `AttributedString` (Swift's native rich text type)
- Apply attributes (fonts, colors, indent) based on the active theme
- This gives you the most control and best native feel

**Option B: Swift-native markdown parser + custom rendering**
- Use Apple's built-in `AttributedString(markdown:)` for basic parsing
- Extend with a custom parser (like `swift-markdown` package) for list-level control
- Render into NSTextView with custom attributes

### Claude Code Prompts

**Prompt 8 — NSTextView Wrapper**

```
Create a MarkdownEditorView for Jottlr that wraps NSTextView in SwiftUI.

Build an NSViewRepresentable called MarkdownTextView that:
1. Wraps NSTextView for rich text editing
2. Takes a Binding<String> for the raw markdown content
3. Uses NSTextStorage with custom attribute application
4. Implements NSTextStorageDelegate to re-parse and re-style on every edit
5. Supports undo/redo (NSTextView has this built in)
6. Uses the system font initially (we'll add theming later)

For markdown parsing:
- Use Apple's swift-markdown package (https://github.com/swiftlang/swift-markdown)
  to parse the markdown AST
- Walk the AST and apply NSAttributedString attributes:
  - # Heading 1 → large bold font
  - ## Heading 2 → medium bold font
  - **bold** → bold
  - *italic* → italic
  - `code` → monospace font with subtle background
  - - bullet items → indented with bullet character
  - [ ] checkboxes → with a clickable checkbox image/character

The editor should feel like Typora or Bear — you type markdown syntax but
see rendered output inline. The syntax characters (like ** or #) should
be visible but styled subtly (lighter color).

This is the foundation we'll build theming on top of, so structure the
attribute-application code to be configurable (pass in fonts/colors
rather than hardcoding them).
```

**Prompt 9 — Editor Integration**

```
Integrate MarkdownTextView into Jottlr's editor.

Replace the basic TextEditor in EditorView with the new MarkdownTextView.

Also:
1. Add a toggle to switch between "Source" mode (plain text) and
   "Rendered" mode (WYSIWYG). Use a segmented control in the toolbar.
2. Ensure cursor position is preserved when switching modes
3. Add line numbers in source mode (a gutter on the left side)
4. Handle the editor scrolling to maintain position during re-parsing
5. Make sure file loading and saving still works with the new editor

Performance consideration: Don't re-parse the entire document on every
keystroke. Only re-parse the changed paragraph/block. Use the
NSTextStorageDelegate's edited range to determine what changed.
```

### Learning Moments

- **`NSViewRepresentable`** — This is how you use traditional macOS AppKit views inside SwiftUI. Think of it like using a native Android View inside Jetpack Compose, or wrapping a jQuery plugin in a React component. You implement `makeNSView()` (create), `updateNSView()` (sync state), and a `Coordinator` class (handle callbacks). This is the most "un-SwiftUI" code you'll write, but it's necessary because SwiftUI's built-in TextEditor is too basic for a real editor.

- **`NSTextStorage` / `NSAttributedString`** — The macOS text system is incredibly powerful. `NSTextStorage` is a subclass of `NSMutableAttributedString` that notifies the layout system when text changes. It's like the DOM — you mutate it, and the rendering engine responds. `NSAttributedString` is like applying inline CSS styles to spans of text.

---

## 6. Phase 4: List Editing Power Features

**Goal:** Make lists feel like a dedicated list editor — keyboard-driven indentation, reordering, and style control, all while keeping the underlying markdown valid.

### What You'll Build

1. **Tab/Shift+Tab** → indent/outdent list items
2. **⌥↑ / ⌥↓** (Option+Arrow) → move list items up/down
3. **Enter** at end of list item → new item at same level
4. **Enter** on empty list item → outdent or exit list
5. **⌘⇧C** → toggle checkbox on current line
6. **⌘⇧7/8/9** → switch list type (ordered/unordered/checkbox)
7. Custom marker rendering per nesting level (from theme)

### Claude Code Prompts

**Prompt 10 — List Keyboard Commands**

```
Add keyboard-driven list editing to Jottlr's MarkdownTextView.

Implement the following keybindings when the cursor is on a list line:

1. Tab → increase indent level (add 2 or 4 spaces before the marker)
2. Shift+Tab → decrease indent level
3. Option+Up Arrow → move the current list item (and its children) up
4. Option+Down Arrow → move the current list item (and its children) down
5. Enter at end of a list item → create new list item at same level
   with the same marker type
6. Enter on an empty list item → remove the marker and outdent
   (or exit the list if at level 0)
7. ⌘⇧C → toggle checkbox (- [ ] ↔ - [x]) on current line

Implementation approach:
- Override keyDown(with:) in the NSTextView coordinator
- Parse the current line to detect if it's a list item and what level
- Manipulate the raw markdown string, then let the re-parser update styling
- Keep the cursor in the correct position after each operation

Create a ListEditingHelper utility that can:
- Detect if a line is a list item (and what type/level)
- Calculate the new markdown when indenting/moving
- Handle nested children when moving items
```

**Prompt 11 — List Rendering Per Level**

```
Add per-level list rendering to Jottlr's markdown editor.

Using the ListLevelStyle configuration (which will come from themes later),
implement level-specific list rendering:

1. Each nesting level can have a different marker symbol
   (e.g., level 0: •, level 1: ◦, level 2: ▪, level 3: ▸)
2. Each level can have different indent spacing
3. Each level can have a different marker color
4. Checkboxes render as interactive toggles (clicking toggles [x] ↔ [ ])
5. Ordered lists show proper sequential numbering even in the WYSIWYG view

For now, use hardcoded default styles. The theme system (Phase 5) will
make these configurable.

The underlying markdown must remain valid standard markdown at all times.
The visual rendering is purely a presentation layer.
```

---

## 7. Phase 5: Theming System

**Goal:** Users can create, edit, and apply visual themes that change how markdown renders — fonts, colors, spacing, and list styles.

### Claude Code Prompts

**Prompt 12 — Theme Engine**

```
Build the theming engine for Jottlr.

Create a ThemeEngine (@Observable class) that:
1. Loads the active Theme from SwiftData
2. Converts Theme properties into NSFont, NSColor, and paragraph style objects
3. Provides a method to generate NSAttributedString attributes for any
   markdown element type (heading, paragraph, bold, italic, code, list, etc.)
4. Supports live preview — when a theme property changes, the editor
   re-renders immediately

Create a ThemeManager that:
1. Provides a list of all available themes
2. Creates built-in default themes on first launch:
   - "Apple Default" — SF Pro, system colors, clean and minimal
   - "Writer" — serif font (New York), warm tones, generous spacing
   - "Developer" — monospace (SF Mono), dark-friendly, compact
3. Handles creating, duplicating, and deleting custom themes

Wire the ThemeEngine into MarkdownTextView so all attribute application
goes through the theme. The theme should be the single source of truth
for all visual styling in the editor.
```

**Prompt 13 — Theme Editor UI**

```
Build the theme editor UI for Jottlr.

Create a ThemeEditorView that:
1. Opens as a sheet or separate window
2. Has a live preview panel showing sample markdown rendered with
   the current theme settings
3. Sections for:
   a. Typography — font pickers for heading/body/mono, base size slider
   b. Colors — color pickers for background, text, accent, headings
   c. Spacing — sliders for paragraph spacing, line height
   d. List Styles — a visual editor for each nesting level:
      - Dropdown to pick marker type (bullet, dash, arrow, number, etc.)
      - Custom symbol input for custom markers
      - Color picker for the marker
      - Indent and padding sliders
      - Small preview of what that level looks like

4. "Save", "Save As New Theme", "Reset to Default" buttons
5. Changes should preview live in the sample panel as the user adjusts

Use Form with Section for the layout — this gives the native macOS
settings-panel look.
Use ColorPicker (SwiftUI built-in) for color selection.
Use a custom font picker that lists system fonts.
```

### Learning Moments

- **`@Observable` as a service layer** — The ThemeEngine is a great example of a shared service in SwiftUI. You create it once, inject it via `.environment()`, and any view that reads from it automatically updates when the theme changes. This is like a React Context provider or a scoped service in .NET DI.

- **`Form` + `Section`** — SwiftUI's Form automatically adapts to the platform. On macOS, it renders as a native settings-style layout with labels on the left and controls on the right. On iOS, it would render as a grouped table view. Same code, different look.

---

## 8. Phase 6: CloudKit Preparation

**Goal:** Ensure everything is ready for CloudKit sync with minimal code changes needed.

### What We Already Did (In Earlier Phases)

- ✅ All `@Model` properties have default values
- ✅ All relationships are optional
- ✅ No `@Attribute(.unique)` anywhere
- ✅ No `.deny` delete rules
- ✅ Only simple CloudKit-compatible types used

### What Remains

1. Add iCloud capability in Xcode (Signing & Capabilities)
2. Create a CloudKit container (iCloud.com.yourteam.Jottlr)
3. Enable Remote Notifications capability
4. On macOS specifically: manually link `CloudKit.framework` in Build Phases (there's a known bug where debug works but release silently fails without this)
5. Test sync between devices

### Claude Code Prompt (When Ready)

```
Prepare Jottlr for CloudKit synchronization.

1. Verify all SwiftData models follow CloudKit rules:
   - All properties have defaults
   - All relationships are optional
   - No @Attribute(.unique)
   - No .deny delete rules

2. Update the ModelContainer configuration to be CloudKit-ready.
   Currently it should work with a local store. When CloudKit is enabled,
   SwiftData handles sync automatically.

3. Add a note about what manual Xcode steps are needed:
   - Add iCloud capability
   - Check CloudKit
   - Add container: iCloud.com.[team].Jottlr
   - Add Background Modes > Remote Notifications (iOS only, not needed for macOS)
   - Link CloudKit.framework in Build Phases (macOS-specific requirement)

4. Add any sync conflict handling if needed (SwiftData uses last-write-wins
   by default, which should be fine for jottings).

Don't actually enable CloudKit yet — just ensure the codebase is ready.
```

---

## 9. Testing Strategy

### Testing in Swift — Mapped to What You Know

| Swift / Xcode | Java | C# / .NET | JavaScript |
|---------------|------|-----------|------------|
| `XCTestCase` | `JUnit` test class | `[TestClass]` in MSTest / xUnit | `describe()` block |
| `func testSomething()` | `@Test void something()` | `[TestMethod]` / `[Fact]` | `it('should...')` |
| `XCTAssertEqual(a, b)` | `assertEquals(a, b)` | `Assert.AreEqual(a, b)` | `expect(a).toEqual(b)` |
| `XCTAssertNil(x)` | `assertNull(x)` | `Assert.IsNull(x)` | `expect(x).toBeNull()` |
| `XCTAssertThrowsError` | `assertThrows()` | `Assert.Throws<T>()` | `expect(() => ...).toThrow()` |
| `setUpWithError()` | `@BeforeEach` | `[TestInitialize]` | `beforeEach()` |
| `tearDownWithError()` | `@AfterEach` | `[TestCleanup]` | `afterEach()` |
| ⌘U (Run tests) | `mvn test` | `dotnet test` | `npm test` |
| `@MainActor` on test | — | `[STAThread]` (loosely) | — |

### What To Test vs What Not To Test

**Test heavily (pure logic, clear inputs/outputs):**
- SwiftData model creation, defaults, and relationships
- `ListEditingHelper` — indent, outdent, move up/down, marker detection
- `MarkdownParser` — AST → attributed string attribute generation
- `ThemeEngine` — hex ↔ color conversion, font resolution, style generation
- `FileSystemService` — read/write/scan (using a temp directory)
- `ThemeManager` — built-in theme creation, CRUD operations
- ViewModel logic — filtering, sorting, search, debounce behavior

**Test lightly (integration/smoke tests):**
- SwiftData persistence round-trips (save → fetch → verify)
- Theme application to a sample markdown string

**Don't unit test (verify manually or with UI tests):**
- SwiftUI view layout and rendering
- `NSViewRepresentable` wrapper behavior
- Menu bar icon appearance
- Global hotkey registration (system-level, requires accessibility permissions)

### SwiftData Testing Pattern

Testing SwiftData requires an in-memory model container. This is the equivalent of using an in-memory SQLite database for EF Core tests, or an H2 database for JPA tests:

```swift
import XCTest
import SwiftData
@testable import Jottlr

final class JottingTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        // In-memory container — like using H2 or EF Core InMemory provider
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Jotting.self, JottingCopy.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testJottingDefaultValues() throws {
        let jotting = Jotting(content: "Test idea")
        XCTAssertFalse(jotting.isPinned)
        XCTAssertTrue(jotting.tags.isEmpty)
        XCTAssertEqual(jotting.content, "Test idea")
    }

    func testJottingPersistenceRoundTrip() throws {
        let jotting = Jotting(content: "Persisted idea")
        context.insert(jotting)
        try context.save()

        let descriptor = FetchDescriptor<Jotting>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.content, "Persisted idea")
    }

    func testJottingCopyRelationship() throws {
        let jotting = Jotting(content: "Original idea")
        context.insert(jotting)

        let copy = JottingCopy(
            destinationFilePath: "/path/to/file.md",
            originalJotting: jotting
        )
        context.insert(copy)
        try context.save()

        XCTAssertEqual(copy.originalJotting?.content, "Original idea")
        XCTAssertEqual(jotting.copies?.count, 1)
    }
}
```

### Testing Pure Logic (No SwiftData Needed)

Services like `ListEditingHelper` are the easiest and most valuable to test:

```swift
final class ListEditingHelperTests: XCTestCase {

    func testDetectUnorderedListItem() {
        let line = "  - Buy groceries"
        let result = ListEditingHelper.parseLine(line)
        XCTAssertEqual(result.level, 1)
        XCTAssertEqual(result.markerType, .dash)
        XCTAssertEqual(result.content, "Buy groceries")
    }

    func testIndentListItem() {
        let line = "- Item one"
        let indented = ListEditingHelper.indent(line)
        XCTAssertEqual(indented, "  - Item one")
    }

    func testOutdentAtRootDoesNothing() {
        let line = "- Already at root"
        let outdented = ListEditingHelper.outdent(line)
        XCTAssertEqual(outdented, "- Already at root")
    }

    func testToggleCheckbox() {
        let unchecked = "- [ ] Buy milk"
        let checked = ListEditingHelper.toggleCheckbox(unchecked)
        XCTAssertEqual(checked, "- [x] Buy milk")

        let uncheckedAgain = ListEditingHelper.toggleCheckbox(checked)
        XCTAssertEqual(uncheckedAgain, "- [ ] Buy milk")
    }
}
```

### Modified Claude Code Prompts — Adding Tests

Append the following to each Claude Code prompt from the main phases:

**Add to Prompt 2 (SwiftData Models):**

```
Also create a JottlrTests target (if it doesn't exist) and add:
- JottingTests.swift: Test default values, persistence round-trip using
  an in-memory ModelContainer, and the JottingCopy relationship.
  Use setUpWithError() to create a fresh in-memory container for each test.
```

**Add to Prompt 3 (Quick Capture Input):**

```
Also add tests for the save logic:
- Test that creating a Jotting with empty content is handled (should it
  be prevented or allowed?)
- Test that the jotting timestamp is approximately "now" when created
```

**Add to Prompt 4 (Jotlog Timeline View):**

```
Also add JotlogViewModelTests.swift:
- Test search filtering — insert 5 jottings, search by keyword, verify
  only matching ones return
- Test sort order — verify jottings come back newest-first
- Test pin behavior — verify pinned jottings can be toggled
```

**Add to Prompt 6 (File Sidebar):**

```
Also add FileSystemServiceTests.swift:
- Use FileManager to create a temp directory in setUpWithError()
  and clean it up in tearDownWithError()
- Test: create a .md file, read it back, verify contents match
- Test: scan a directory tree with nested folders, verify all .md files found
- Test: non-.md files are excluded from scan results
- Test: write to a file, verify the file on disk changed
```

**Add to Prompt 8 (NSTextView Wrapper):**

```
Also add MarkdownParserTests.swift:
- Test heading detection: "# Title" → attributes include large bold font
- Test bold: "**word**" → attributes include bold trait
- Test italic: "*word*" → attributes include italic trait
- Test code: "`code`" → attributes include monospace font
- Test list item: "- item" → attributes include indent
- Test nested list: "  - item" → attributes include deeper indent
- Test mixed: "**bold** and *italic*" → correct attributes on correct ranges
```

**Add to Prompt 10 (List Keyboard Commands):**

```
Also add ListEditingHelperTests.swift with comprehensive tests:
- Detect list items: unordered (-, *, +), ordered (1.), checkbox (- [ ], - [x])
- Detect indent level from leading whitespace
- Indent: adds correct whitespace prefix
- Outdent: removes whitespace prefix, stops at level 0
- Move up/down: swaps lines correctly, handles edge cases (first/last item)
- Toggle checkbox: [ ] ↔ [x]
- New item creation: correct marker type and indent carried forward
- Edge cases: empty lines, non-list lines, deeply nested items
```

**Add to Prompt 12 (Theme Engine):**

```
Also add ThemeEngineTests.swift:
- Test hex → NSColor conversion (including edge cases: 3-digit hex, with/without #)
- Test NSColor → hex round-trip
- Test font resolution: verify system font fallback when a named font doesn't exist
- Test attribute generation: given a theme, verify correct font/color/spacing
  for headings, body, code, lists
- Test list level style: verify correct marker and indent for levels 0-3

Also add ThemeManagerTests.swift:
- Test built-in themes are created on first access
- Test creating a custom theme
- Test duplicating a theme
- Test deleting a custom theme (should succeed)
- Test deleting a built-in theme (should fail or be prevented)
```

### Test File Structure

```
JottlrTests/
├── Models/
│   ├── JottingTests.swift
│   └── ThemeTests.swift
│
├── Services/
│   ├── FileSystemServiceTests.swift
│   ├── MarkdownParserTests.swift
│   ├── ListEditingHelperTests.swift
│   └── ThemeManagerTests.swift
│
├── ViewModels/
│   ├── JotlogViewModelTests.swift
│   └── ThemeEngineTests.swift
│
└── Utilities/
    └── ColorExtensionsTests.swift
```

### Running Tests

- **⌘U** in Xcode runs all tests
- **Click the diamond** next to a test function to run just that one
- **Test Navigator** (⌘6) shows all tests organized by class
- Tests run in a random order by default (good — exposes hidden state dependencies)
- CI: `xcodebuild test -scheme Jottlr -destination 'platform=macOS'`

---

## 10. Swift/SwiftUI Concepts for Java/C#/Web Developers

### The Big Picture

| Swift/SwiftUI | Java | C# | Web (React) |
|---------------|------|-----|-------------|
| `struct` (value type) | — (no exact equiv) | `struct` | — |
| `class` (reference type) | `class` | `class` | `class` |
| `protocol` | `interface` | `interface` | TypeScript `interface` |
| `extension` | — (open classes in Kotlin) | Extension methods | — |
| `Optional<T>` (`T?`) | `Optional<T>` | `T?` (nullable) | `T \| undefined` |
| `guard let x = y else` | — | — | Early return pattern |
| `if let x = y` | `if (y != null) { var x = y; }` | `if (y is T x)` | `if (y) { const x = y; }` |
| `@State` | — | — | `useState()` |
| `@Binding` | — | — | Passing `setState` to child |
| `@Observable` | — | `INotifyPropertyChanged` | MobX observable |
| `@Query` | — | `DbContext` + binding | React Query |
| `@Environment` | `@Inject` | `IServiceProvider` | `useContext()` |
| `View` protocol | — | `UserControl` | React Component |
| `body: some View` | — | `Render()` | `return <JSX>` |
| `VStack/HStack/ZStack` | — | `StackPanel` | `flex-direction: column/row` |
| `.modifier()` calls | Builder pattern | Fluent API | JSX props |
| `Binding<T>` | — | Two-way binding | `[value, setValue]` pair |

### Key Swift Language Features

**Optionals** — Swift's killer feature for null safety:
```swift
var name: String? = nil    // Like C# nullable: string? name = null;
let unwrapped = name ?? "Default"  // Null coalescing, same as C#
if let name = name { print(name) } // Safe unwrap — only runs if non-nil
guard let name = name else { return } // Early exit if nil
```

**Closures** — Like lambdas in Java/C#:
```swift
// Swift closure
let doubled = numbers.map { $0 * 2 }
// Java lambda
// numbers.stream().map(n -> n * 2)
// C# lambda
// numbers.Select(n => n * 2)
```

**Trailing closure syntax** — Most SwiftUI code uses this:
```swift
// These are equivalent:
Button(action: { print("tap") }, label: { Text("Click") })
Button("Click") { print("tap") }  // Trailing closure
```

**Property wrappers** — The `@` annotations:
```swift
@State var count = 0        // @State is a property wrapper
// It's syntactic sugar for a more complex pattern
// Think of @State as adding a hidden "onChange" listener to a variable
```

---

## 11. Claude Code Workflow Guide

### General Tips

1. **Always start with `claude` in your terminal** from the Xcode project directory
2. **Give Claude Code context about what exists** — "Look at my project structure first" is a great opening
3. **One prompt = one feature** — don't try to build everything at once
4. **Build in Xcode after each prompt** — fix compile errors before moving on
5. **Feed errors back** — paste Xcode error messages into Claude Code and ask it to fix them
6. **Commit after each working feature** — `git add -A && git commit -m "Phase 1: menu bar shell"`
7. **Use `claude --help`** to see available flags

### Prompt Engineering for Claude Code

**Good prompts:**
- Reference existing files: "Update JottlrApp.swift to add..."
- Specify file locations: "Create this in a Models/ subfolder"
- Describe behavior, not implementation: "When the user presses Enter, save the jotting"
- Mention constraints: "All SwiftData properties must have default values"

**Bad prompts:**
- "Build the app" (too vague)
- "Make it look good" (subjective, no direction)
- Prompts that combine 5+ unrelated features

### Error Resolution Workflow

```
1. You: [give Claude Code a prompt]
2. Claude Code: [writes/modifies files]
3. You: Build in Xcode (⌘B)
4. If errors:
   You: "I'm getting these errors: [paste errors]. Fix them."
5. Claude Code: [fixes the issues]
6. Repeat until it builds
7. You: Run the app (⌘R), test the feature
8. If behavior is wrong:
   You: "When I [action], [what happens]. It should [expected behavior]."
9. When it works: git commit
```

---

## 12. Project Structure

```
Jottlr/
├── JottlrApp.swift                  # App entry point, MenuBarExtra + Window scenes
├── Info.plist                       # LSUIElement = YES, etc.
│
├── Models/
│   ├── Jotting.swift                # SwiftData model
│   ├── JottingCopy.swift            # SwiftData model
│   └── Theme.swift                  # SwiftData model + ListLevelStyle
│
├── Views/
│   ├── MenuBar/
│   │   ├── QuickCaptureView.swift   # Hotkey-triggered input
│   │   └── JotlogView.swift         # Chat-history timeline
│   │
│   ├── Editor/
│   │   ├── EditorView.swift         # Main editor layout (NavigationSplitView)
│   │   ├── FileTreeView.swift       # Directory sidebar
│   │   ├── MarkdownTextView.swift   # NSViewRepresentable WYSIWYG editor
│   │   └── JotlogSidebarView.swift  # Right sidebar for copying jottings
│   │
│   └── Theme/
│       ├── ThemeEditorView.swift    # Theme creation/editing UI
│       └── ThemePreviewView.swift   # Live preview panel
│
├── ViewModels/
│   ├── EditorViewModel.swift        # @Observable — file state, active document
│   ├── JotlogViewModel.swift        # @Observable — jotlog filtering, search
│   └── ThemeEngine.swift            # @Observable — active theme, attribute generation
│
├── Services/
│   ├── FileSystemService.swift      # File read/write/watch
│   ├── MarkdownParser.swift         # AST parsing + attribute generation
│   ├── ListEditingHelper.swift      # List manipulation logic
│   └── ThemeManager.swift           # Theme CRUD, built-in themes
│
├── Utilities/
│   ├── KeyboardShortcutNames.swift  # KeyboardShortcuts.Name extensions
│   ├── DateFormatters.swift         # Relative date formatting
│   └── ColorExtensions.swift        # Hex ↔ NSColor conversion
│
└── Resources/
    └── Assets.xcassets              # App icon, menu bar icon

JottlrTests/
├── Models/
│   ├── JottingTests.swift
│   └── ThemeTests.swift
├── Services/
│   ├── FileSystemServiceTests.swift
│   ├── MarkdownParserTests.swift
│   ├── ListEditingHelperTests.swift
│   └── ThemeManagerTests.swift
├── ViewModels/
│   ├── JotlogViewModelTests.swift
│   └── ThemeEngineTests.swift
└── Utilities/
    └── ColorExtensionsTests.swift
```

---

## 13. Dependencies

| Package | Purpose | URL |
|---------|---------|-----|
| KeyboardShortcuts | Global hotkey support | https://github.com/sindresorhus/KeyboardShortcuts |
| swift-markdown | Markdown AST parsing | https://github.com/swiftlang/swift-markdown |

That's it — just two dependencies. Everything else uses Apple's built-in frameworks:
- **SwiftData** — persistence
- **SwiftUI** — UI
- **AppKit** (via NSViewRepresentable) — rich text editing
- **CloudKit** (future) — sync

Keeping dependencies minimal is important for a macOS app — each dependency is a maintenance risk and a potential source of App Store rejection.

---

## 14. Design Principles

### Look & Feel

Jottlr should look like Apple built it. This means:

1. **Use SF Pro and SF Mono** as default fonts (they're the system fonts)
2. **Use system colors** — `Color.primary`, `Color.secondary`, `Color.accentColor`
3. **Use SF Symbols** for all icons — Apple's built-in icon set with 5000+ icons
4. **Respect Dark Mode** — never hardcode colors; use semantic system colors
5. **Native controls** — use SwiftUI's built-in `Button`, `TextField`, `Toggle`, `Picker` etc.
6. **Proper spacing** — use `.padding()` and the default spacing values
7. **Toolbar style** — use `.toolbar {}` with proper `ToolbarItem` placement
8. **Window chrome** — let macOS handle the title bar; don't customize it

### Keyboard-First Design

Jottlr is for people who think faster than they can click:

- **Every action has a keyboard shortcut**
- **Tab navigation works correctly** between all interactive elements
- **Focus states are visible** — the user should always know where their cursor is
- **The quick capture flow is: hotkey → type → Enter → done** (under 2 seconds)

### Data Integrity

- **Jottings are immutable after creation** — editing the copy in a markdown file doesn't change the original
- **Auto-save everything** — the user should never lose work
- **Undo/redo everywhere** — NSTextView provides this for free in the editor
- **The markdown file is always valid** — no matter what the WYSIWYG renderer shows, the underlying `.md` file should open correctly in any markdown editor

---

## Appendix: Quick Reference for Common Tasks

### "How do I... in Swift?"

| Task | Java/C# | Swift |
|------|---------|-------|
| Print to console | `System.out.println()` | `print()` |
| String interpolation | `"Hello " + name` | `"Hello \(name)"` |
| Array | `List<String>` | `[String]` or `Array<String>` |
| Dictionary | `Map<String, Int>` | `[String: Int]` |
| For loop | `for (var x : list)` | `for x in list` |
| Async function | `CompletableFuture` / `Task` | `async/await` (same as C#!) |
| Try/catch | `try { } catch { }` | `do { try x } catch { }` |
| Switch | `switch(x) { case: }` | `switch x { case .a: }` (no fallthrough!) |
| Null check | `if (x != null)` | `if let x = x` or `guard let x = x else` |
| Create instance | `new MyClass()` | `MyClass()` (no `new` keyword) |
| Type casting | `(MyType) obj` | `obj as? MyType` (safe) or `obj as! MyType` (force) |
| Enum with data | — | `enum Result { case success(Data), case failure(Error) }` |
