# Understanding AggregatorBuddy (for a Web Developer)

A guide to how this iOS app is put together, explained with web analogies. Read
this to navigate the code, understand *why* things are structured this way, and
feel confident making edits.

---

## 1. The 30-second mental model

AggregatorBuddy is a **link saver**. You share a link from any app (Safari,
LinkedIn…) into it, fill a small form, and it shows up in a scrollable list you
can search, filter, tag, and open later. Everything is stored **on the device** —
no server, no accounts, no network.

If you think in web terms:

| Web concept | AggregatorBuddy equivalent |
|---|---|
| React/Vue components | **SwiftUI views** (`HomeFeedView`, `CardView`, …) |
| Component local state (`useState`) | `@State` |
| Global store (Redux/Context) | `@Environment`, the shared `ModelContainer` |
| IndexedDB / localStorage | **SwiftData** (a local database) |
| Your DB schema / an ORM model | the `Item` `@Model` class |
| `npm run build` / bundler config | the **Xcode project** (`.xcodeproj`) |
| A browser extension that adds a "Share to X" button | the **Share Extension** target |
| `package.json` scripts + env | **build settings** & **entitlements** |

---

## 2. Folder-by-folder tour

```
aggregatorBuddy/                         ← repo root
├── AggregatorBuddy.xcodeproj/           ← the "project file" (like a bundler config)
├── AggregatorBuddy/                     ← the MAIN APP source code
│   ├── AggregatorBuddyApp.swift         ← app entry point (like index.tsx / main.ts)
│   ├── Models/
│   │   └── Item.swift                   ← the data model (one saved link) + schema
│   ├── Views/                           ← all the screens/components (SwiftUI)
│   │   ├── HomeFeedView.swift           ← the main list screen
│   │   ├── CardView.swift               ← a single row/card component
│   │   ├── FilterSheetView.swift        ← the filter modal + filter state
│   │   ├── ItemDetailView.swift         ← the view/edit-one-item screen
│   │   └── EmptyStateView.swift         ← "nothing saved yet" placeholder
│   ├── Shared/
│   │   └── AppGroupConfig.swift         ← DB connection setup shared with the extension
│   ├── Support/
│   │   ├── Theme.swift                  ← colors + date formatting (like a theme.css / tokens)
│   │   └── FlowLayout.swift             ← a custom layout helper for wrapping chips
│   ├── Extensions/
│   │   └── URL+Helpers.swift            ← small utility functions
│   └── Assets.xcassets/                 ← images, app icon, colors (static assets folder)
│
├── AggregatorBuddyShareExtension/       ← the SHARE EXTENSION source code (2nd target)
│   ├── ShareViewController.swift        ← the entry point of the extension
│   ├── ShareEntryView.swift             ← the little "Save to AggregatorBuddy" form
│   ├── Info.plist                       ← config: "I am a Share option, show me for URLs/text"
│   └── AggregatorBuddyShareExtension.entitlements  ← permission to access the shared DB
│
├── Documents/                           ← the spec + wireframes (not code, just reference)
├── plan.md                              ← our build log / checklist
└── UnderstandApp.md                     ← this file
```

**Key idea:** a folder is just organization for humans. What *actually* decides
whether a file is compiled is which **target** it belongs to (see §4). In this
project the folders happen to line up with targets, but that's a convention, not
a rule.

---

## 3. What is a "target"? (and the `.xcodeproj`)

### The `.xcodeproj`
`AggregatorBuddy.xcodeproj` is **not** source code — it's the build
configuration for the whole project. Think of it as a much more powerful
`package.json` + `webpack.config.js` combined. It records:
- which files compile into which product,
- build settings (min iOS version, bundle IDs, signing),
- which "targets" exist.

You rarely edit it by hand; you change it through **Xcode's UI** (clicking the
project in the sidebar → tabs like *General*, *Signing & Capabilities*, *Build
Settings*). Internally it's a text file (`project.pbxproj`) — editable, but
fragile, so prefer the UI.

### A "target"
A **target** = one buildable thing (one output product) + the set of source
files and settings that produce it.

- Web analogy: imagine one repo that builds **two** bundles — say a main SPA and
  a separate browser-extension bundle — each with its own entry point and its
  own output. Each of those is a "target."

This project has **two targets**:
1. **`AggregatorBuddy`** → builds the app (`AggregatorBuddy.app`)
2. **`AggregatorBuddyShareExtension`** → builds the share extension
   (`AggregatorBuddyShareExtension.appex`), which gets **embedded inside** the
   app.

Each target has:
- a **bundle identifier** (a unique ID, like a package name):
  - app: `com.nitishsharma.aggregatorbuddy`
  - extension: `com.nitishsharma.aggregatorbuddy.AggregatorBuddyShareExtension`
- its own **Info.plist** (metadata) and **entitlements** (permissions),
- a **deployment target** (minimum iOS version — here iOS 17.0).

### "Target membership" — the crucial concept
A single `.swift` file can belong to **one or more** targets. This is set per
file in Xcode's **File Inspector → Target Membership** (checkboxes).

Example that bit us during the build: `Item.swift` and `AppGroupConfig.swift`
live in the main app's folder, but the **extension also needs them**, so they're
ticked for *both* targets. That's how both the app and the extension share the
exact same `Item` definition and database setup without duplicating code.

> This project uses "synchronized folder groups" (a newer Xcode feature): every
> file in a target's folder is auto-included in that target. That's why dropping
> a new `.swift` file into `AggregatorBuddy/Views/` just works — no manual step.
> The exception is files you want shared across targets, which still need the
> extra checkbox.

---

## 4. Why do we need TWO targets?

Because of how iOS **sandboxing** works.

On iOS, every app runs in its own locked "sandbox" — it cannot see other apps'
data or reach into other apps. So when you're in Safari and tap **Share**, Safari
can't just call our app. Instead, iOS has a system: apps can ship small plug-ins
called **extensions** that the OS loads *inside the context of the sharing app*.

- The **Share Extension** is that plug-in. It's the thing that appears in the
  iOS share sheet. It runs as its **own process**, briefly, on top of Safari.
- The **main app** is the normal app you launch from the home screen.

They are **two separate programs in two separate sandboxes**. They cannot share
memory or variables. The only way they communicate is through a shared
**database file** (see §5).

Web analogy: it's like a **browser extension** (runs injected into other pages)
versus your **main web app** (runs on its own origin). Different execution
contexts; they can only talk through some shared storage or messaging channel.

So: 2 targets = 2 programs = the app + the "Share to AggregatorBuddy" button.

---

## 5. How the two targets connect: App Groups + SwiftData

This is the heart of the app, so let's go slowly.

### SwiftData (the database)
`Item.swift` defines what one saved link looks like:

```swift
@Model
final class Item {
    var id: UUID
    var url: String
    var title: String
    var source: String
    var notes: String?
    var dateAdded: Date
    var isRead: Bool
    var tags: [String]
}
```

`@Model` is a macro that turns this plain class into a **database table row**.
SwiftData (Apple's local database, sitting on top of SQLite) handles saving,
loading, and querying. Roughly: `@Model` ≈ an ORM entity (like a Prisma model).

The database itself is a file on disk. A **`ModelContainer`** is the object that
opens/represents that database file — like a DB connection/handle.

### The problem: two sandboxes, one database
Normally each app's database lives *inside its own sandbox*, invisible to
anything else. But we need the **extension to write** a new `Item` and the
**main app to read** it. Different sandboxes → they'd normally have different,
private databases.

### The solution: an "App Group"
An **App Group** is an Apple-granted shared container — a folder that multiple
targets from the same developer are *allowed* to share. Ours is:

```
group.com.nitishsharma.aggregatorbuddy
```

Both targets declare access to it in their **`.entitlements`** file (entitlements
= the list of special permissions a target is granted; like OAuth scopes). We
then point the database at that shared folder. That's this file —
`Shared/AppGroupConfig.swift`:

```swift
enum AppGroup {
    static let identifier = "group.com.nitishsharma.aggregatorbuddy"
}

enum SharedModelContainer {
    static let shared: ModelContainer = {
        let config = ModelConfiguration(
            groupContainer: .identifier(AppGroup.identifier)   // ← put the DB in the shared folder
        )
        return try! ModelContainer(for: Item.self, configurations: config)
    }()
}
```

Because **both** targets use `SharedModelContainer.shared` (the file is a member
of both targets), they open the **same database file** in the shared App Group
folder. The extension inserts a row; the app reads it. That's the whole
connection.

```
   Safari  ──tap Share──►  Share Extension        Main App
                           (writes Item)          (reads Items)
                                  │                     ▲
                                  ▼                     │
                        ┌─────────────────────────────────────┐
                        │  App Group shared folder             │
                        │  SwiftData store (one SQLite file)   │
                        └─────────────────────────────────────┘
```

### One important quirk
SwiftData's live-updating query (`@Query`) does **not** automatically notice
writes made by the *other* process (the extension). So the main app can't rely
on auto-refresh for items added by the extension. Our fix: `HomeFeedView`
manually re-runs its fetch whenever the app comes back to the foreground
(`scenePhase == .active`) and when returning from the detail screen. That's why
a newly shared item appears the moment you switch to the app.

---

## 6. How the main app is wired (request flow)

Start at the entry point, `AggregatorBuddyApp.swift`:

```swift
@main                                    // ← "this is where the app starts" (like main())
struct AggregatorBuddyApp: App {
    var body: some Scene {
        WindowGroup {                    // ← the app's window
            HomeFeedView()               // ← the first screen shown
        }
        .modelContainer(SharedModelContainer.shared)  // ← inject the DB into the view tree
    }
}
```

`.modelContainer(...)` makes the database available to every view below it via
the environment (like wrapping your app in a `<Provider>`). Views then read it
with `@Environment(\.modelContext)`.

Then the screens compose like components:

- **`HomeFeedView`** — the main screen. Holds the list, the search text, the
  active filters, and the fetch logic. Owns state with `@State`. Decides whether
  to show the empty state, the "no results" state, or the list.
  - renders many **`CardView`** — a pure presentational component; you hand it an
    `Item`, it draws the card. (Like `<Card item={item} />`.)
  - opens **`FilterSheetView`** as a modal (`.sheet`).
  - navigates to **`ItemDetailView`** on long-press (`.navigationDestination`).
- **`ItemDetailView`** — view/edit one item; writes changes back to the DB.
- **`FilterSheetView`** — also defines `FilterState` (the struct describing which
  filters are on) and how an `Item` is matched.

Data flow, end to end:
1. `HomeFeedView.refresh()` runs a `FetchDescriptor` (a query) → loads `[Item]`.
2. `filteredItems` narrows that list by search text + filters (plain Swift, in
   memory).
3. `ForEach(filteredItems)` renders a `CardView` per item.
4. Tapping a card → `open()` marks it read + opens Safari.
   Long-press → sets `selectedItem` → navigates to `ItemDetailView`.
5. Edits/deletes call into the `modelContext` (the DB), then the list re-fetches.

---

## 7. SwiftUI in one page (the web-dev version)

- A **View** is a struct with a `body` — like a function component returning JSX.
  It's recreated cheaply and often; don't fear "re-renders."
- **State wrappers** (property wrappers) tell SwiftUI what to watch:
  - `@State` — local component state (`useState`). Owned by this view.
  - `@Binding` — a two-way handle to someone else's `@State` (a value + its
    setter passed down; like `value`+`onChange` combined).
  - `@Environment` — pull something from context (DB, dismiss action, color
    scheme). Like `useContext`.
  - `@Bindable` — lets you make two-way bindings into an `@Model`/observable
    object's fields.
- **Modifiers** are chained methods that wrap a view: `.padding()`,
  `.background()`, `.onTapGesture { }`. Read them like CSS + event handlers,
  applied outside-in. Order matters.
- **Layout containers**: `VStack` (column), `HStack` (row), `ZStack` (layers),
  `List` (a scrolling table), `ScrollView`. Think flexbox with named directions.
- **Navigation**: `NavigationStack` is the router; `.navigationDestination`
  pushes a screen; `.sheet` presents a modal.

You don't manually re-render. You mutate `@State`/model data, and SwiftUI
recomputes the affected `body`s automatically (like React's reconciler).

---

## 8. Config files you'll meet

- **`Info.plist`** — an XML metadata file per target. For the extension it's
  important: it declares "I'm a share extension, offer me for URLs and text, and
  my entry class is `ShareViewController`." (No storyboard — we host SwiftUI.)
- **`*.entitlements`** — the special permissions a target has. Here: access to
  the App Group. (Web analogy: capability flags / OAuth scopes.)
- **Build settings** (in the `.xcodeproj`, edited via Xcode UI) — things like
  `IPHONEOS_DEPLOYMENT_TARGET` (min iOS = 17.0), `PRODUCT_BUNDLE_IDENTIFIER`,
  code signing. Like build-time env vars.
- **`Assets.xcassets`** — the asset catalog: app icon, images, named colors.

---

## 9. How to make common edits (a cheat sheet)

| I want to… | Go to… |
|---|---|
| Change how a card looks | `Views/CardView.swift` |
| Change colors / date format | `Support/Theme.swift` |
| Add/remove a field on a saved link | `Models/Item.swift` (⚠ changes the DB schema — see below) |
| Change the main list / search / sort | `Views/HomeFeedView.swift` |
| Change the filter options or logic | `Views/FilterSheetView.swift` (`FilterState`) |
| Change the view/edit screen | `Views/ItemDetailView.swift` |
| Change the share form | `AggregatorBuddyShareExtension/ShareEntryView.swift` |
| Change what content the share sheet accepts | `AggregatorBuddyShareExtension/Info.plist` |
| Change min iOS version / bundle ID / signing | Xcode → select project → *General* / *Signing & Capabilities* |
| Add a brand-new screen | add a `SomethingView.swift` under `Views/` (auto-included in the app target) |
| Add code the extension ALSO needs | create the file, then tick **both** targets in File Inspector → Target Membership |

> ⚠️ **Editing `Item` (the model):** adding a simple optional field or a field
> with a default value is usually safe (SwiftData migrates automatically).
> Renaming/removing fields or changing types can require a migration and may
> wipe local data during development. When experimenting, deleting the app from
> the simulator resets the database.

---

## 10. The build/run loop (vs. `npm run dev`)

- There's no hot-reload dev server. You press **Run (▶)** in Xcode; it compiles
  and installs the app on a **simulator** (or device) and launches it.
- **Xcode Previews** (`#Preview { ... }` blocks) are the closest thing to
  live-reloading a single component — a canvas that renders one view in
  isolation.
- To test the extension: run the **AggregatorBuddyShareExtension** scheme and
  pick a host app (e.g. Safari) — iOS opens Safari with your extension available
  in the share sheet.
- The **scheme** selector (top of Xcode) chooses *what* runs — the app or the
  extension. Think of it as picking which npm script to run.

Gotchas we hit, worth remembering:
- This project lives in **iCloud Drive**, which can cause files to look
  out-of-date momentarily. If something seems wrong on disk, give iCloud a
  second to sync.
- Creating the Share Extension target made Xcode generate a default
  `ShareViewController` that **overwrote** ours; if you ever recreate it, re-apply
  our version.

---

## 11. Glossary

- **Target** — one buildable product (app or extension) + its files/settings.
- **Scheme** — a saved "what to build & run" selection in Xcode.
- **Bundle identifier** — unique app/extension ID (reverse-DNS, like a package name).
- **Sandbox** — the isolated environment each app/extension runs in.
- **Extension (app extension)** — a small plug-in the OS runs inside other apps
  (our Share Extension).
- **App Group** — an Apple-granted shared storage container multiple targets can access.
- **Entitlements** — the special permissions a target is granted.
- **Info.plist** — per-target metadata/config (XML).
- **SwiftData / `@Model` / `ModelContainer` / `ModelContext`** — the local
  database, a table/entity, the DB connection, and the working "session" you
  read/write through.
- **SwiftUI** — the declarative UI framework (React-like).
- **Property wrappers** (`@State`, `@Binding`, `@Environment`, …) — annotations
  that connect a variable to SwiftUI's state system.
- **Modifier** — a chained method that configures/wraps a view.
```
