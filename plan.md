# AggregatorBuddy — Build Plan & Progress Log

> Living document. As we build, we tick off tasks and log details, decisions, and gotchas here.
> Source of truth for scope: `Documents/AggregatorBuddy_Technical_Spec.md` + `Documents/aggregatorbuddy_wireframes.html`.

Last updated: 2026-09-20

---

## 1. Locked Decisions

| # | Decision |
|---|---|
| App name | **AggregatorBuddy** |
| Bundle ID | `com.nitishsharma.aggregatorbuddy` |
| App Group | `group.com.nitishsharma.aggregatorbuddy` |
| Platform | iOS **17.0+**, iOS-only (drop template's 27.0 + macOS/visionOS) |
| UI | SwiftUI |
| Persistence | SwiftData, local only (no CloudKit) |
| Share Extension | **SwiftUI-hosted** in a `UIHostingController` |
| Source autocomplete | **Skipped** for Phase 1 |
| Card tap | **Open link in Safari + mark read** |
| Card long-press | **Open Detail/Edit view** |
| Nav title | **"Saved"** (per wireframe) |
| `Item.id` | plain `UUID` (no `@Attribute(.unique)`) |
| Dates | Absolute format (e.g. "Sep 20, 2026") |
| Filter UI | Modal sheet + filter icon with active-count badge |

### Design tokens (from wireframes)
| Token | Hex |
|---|---|
| Background | `#FAFAF8` |
| Card | `#FFFFFF` |
| Ink | `#1C1C1E` |
| Ink secondary | `#6E6E73` |
| Teal accent | `#2F6F5E` |
| Amber | `#D9863F` |
| Red / destructive | `#C1462F` |

---

## 2. Work Split

- **Claude writes:** all Swift code, data model, App Group container factory, project.pbxproj edits (bundle ID, deployment target).
- **User does in Xcode UI (~2 min):** add the Share Extension target; enable App Groups capability on **both** targets. Claude provides click-by-click steps.

---

## 3. Task Checklist

### Phase 0 — Project setup
- [x] Rename project MyApp → AggregatorBuddy (done in earlier session)
- [x] Set bundle ID to `com.nitishsharma.aggregatorbuddy` in project.pbxproj
- [x] Lower deployment target to iOS 17.0; drop macOS/visionOS platforms (SUPPORTED_PLATFORMS = iphoneos iphonesimulator, device family 1,2)
- [x] Add `Shared/AppGroupConfig.swift` (App Group ID constant + ModelContainer factory via `groupContainer: .identifier`)

### Phase 1 — Data model
- [x] `Models/Item.swift` — SwiftData `@Model`

### Phase 2 — Main app UI
- [x] `AggregatorBuddyApp.swift` — app entry, wire shared ModelContainer (re-fetch on scenePhase handled in HomeFeedView)
- [x] `Views/HomeFeedView.swift` — manual fetch + scenePhase refetch, `.searchable`, filter toolbar btn + badge, tap=open/long-press=detail, swipe read/delete, empty + no-results states
- [x] `Views/CardView.swift` — card cell (title/source/date/tags/read dot)
- [x] `Views/FilterSheetView.swift` — modal filter sheet (tag/source multi-select, read segmented, apply/clear + badge count)
- [x] `Views/ItemDetailView.swift` — view/edit all fields, open link, delete w/ confirm
- [x] `Views/EmptyStateView.swift` (+ NoResultsView)
- [x] `Extensions/URL+Helpers.swift` — URL normalization + NSDataDetector link extraction
- [x] `Support/Theme.swift` (brand colors + card date format), `Support/FlowLayout.swift` (chip wrapping)

### Phase 3 — Share Extension
- [x] User added Share Extension target (Xcode used a **synchronized folder group** → my Swift files auto-compile into the extension)
- [x] Fixed post-target-creation: Info.plist restored to principal-class (no storyboard), deleted `MainInterface.storyboard`, extension deployment target → 17.0, wired `CODE_SIGN_ENTITLEMENTS` + excluded entitlements from resource membership
- [x] User ticked target membership of `Item.swift` + `AppGroupConfig.swift` for the extension (pbxproj exception set confirms)
- [x] **Gotcha fixed:** Xcode's target creation had OVERWRITTEN my `ShareViewController.swift` with its default `SLComposeServiceViewController` template (→ old "Post/Cancel" UI appeared at runtime). iCloud caching masked this in earlier reads. Rewrote it with the SwiftUI-hosting version. `ShareEntryView.swift` was unaffected.
- [x] Added missing `import SwiftData` to ShareViewController (needed for `.modelContainer`)
- [x] ✅ **Verified end to end:** share from Safari → SwiftUI form appears → Save → entry shows in the app feed. Cross-process App Group write + scenePhase re-fetch confirmed working.
- [x] `ShareViewController.swift` — UIHostingController entry (3-step containment), parse NSItemProvider (public.url / public.plain-text fallback via NSDataDetector)
- [x] `ShareEntryView.swift` — manual metadata form (URL, Title, Source, Tags, Notes) + Save/Cancel, writes to shared container
- [x] `Info.plist` activation rules (WebURL max 1 + Text), NSExtensionPrincipalClass = `$(PRODUCT_MODULE_NAME).ShareViewController`, no storyboard
- [x] `AggregatorBuddyShareExtension.entitlements` — App Group
- Files staged in `AggregatorBuddyShareExtension/` folder; user wires them into the new target.

### Phase 4 — Verify against acceptance criteria
- **2026-09-20 code audit** of all 12 spec §9 criteria: all implemented. Bug found & fixed: deleting/editing from Detail left a stale/deleted `@Model` ref in HomeFeed's `items` (crash/stale risk) → added `.onChange(of: selectedItem)` refresh on detail dismiss. Flagged for live test: card tap-vs-long-press gesture combo in List (may need Button + simultaneousGesture if finicky).
- [x] Share from another app → item saved
- [x] Saved item appears immediately in feed (re-fetch on active)
- [x] Card shows title/source/date/tags/read state
- [x] Tap opens Safari + marks read
- [x] Toggle read/unread
- [x] Delete with confirmation
- [x] Search across title/source/notes
- [x] Filter by tag/source/read status, combinable, with badge
- [x] Detail view edit + delete
- [x] Data persists across restarts
- [x] No network calls anywhere

✅ **All Phase 1 acceptance criteria verified working in the simulator (2026-09-20).**
✅ **Running on physical iPhone (2026-09-20)** — free Personal Team (App Groups accepted), trusted dev cert on device, full flow works. See `RunOnDevice.md` for the 7-day renewal steps.

---

## 4. Known Caveats
- SwiftData `@Query` does **not** auto-refresh on cross-process writes from the Share Extension → main app must re-fetch on `scenePhase == .active` to satisfy "saved items appear immediately".
- SwiftData `#Predicate` array `contains` on `[String]` tags is unreliable → filter tags **in-memory** after fetch (fine at Phase 1 data volumes).

---

## 4b. Phase 2 — Feature Plan (decided 2026-09-21)

Reverses Phase 1's "no network" rule (features 1–2 fetch). Build order: **4 → 2 → 3 → 1**.

- **F4 · Read styling** — dim the whole read card to ~55% opacity; tap/long-press behavior unchanged. Offline, no model change. `CardView`.
- **F2 · Source auto-detect** — derive source from URL domain (LinkedIn/Instagram/Twitter-X/YouTube/… else bare domain), prefill Source in the share form. Offline, no model change. `Item.detectSource(from:)` + `ShareEntryView`.
- **F3 · Tag input** — removable chips + live suggestions from existing tags; new tags auto-join the derived list. Offline, no model change. New reusable SwiftUI token component used in share form + detail edit.
- **F1 · URL preview (+ auto-title)** — LinkPresentation `LPMetadataProvider`, **fetch-once-and-cache** in the app (not extension). Also auto-fills empty Title from fetched page title. Network + model change: add `previewImageData: Data?` (`.externalStorage`) + `previewFetchAttempted: Bool` (lightweight SwiftData migration). Failed/no-image → text-only card; optional manual refresh in detail.

### Phase 2 progress
- [x] F4 read styling — `CardView` dims to 0.55 opacity when read (code done, awaiting device test)
- [x] F2 source auto-detect — `Item.detectSource(from:)` + `ShareEntryView` prefills Source from URL domain (code done, awaiting device test)
- [x] F3 tag chips + suggestions — ✅ verified working in both share form and in-app edit. `Support/TagInputField.swift` added to extension target membership by user.
- [x] F1 url preview + auto-title — `Item` gains `previewImageData: Data?` (`.externalStorage`) + `previewFetchAttempted: Bool` (auto lightweight migration). New app-only `Support/LinkPreviewFetcher.swift` (LinkPresentation `LPMetadataProvider`). `HomeFeedView.reload()` = refresh + `fetchMissingPreviews()` (fetch-once per item, auto-fills empty title). `CardView` shows a 140pt banner image when cached. No new extension membership; network now used.

✅ **All Phase 2 features (F1–F4) verified on device (2026-09-22).** Titles auto-fill, preview images show (Google), login-walled links (LinkedIn) gracefully fall back to text-only, manual titles preserved.
Optional follow-ups deferred: preview image in detail view; manual "refresh preview" button.

## 4c. Phase 2b — Card redesign (compact + states) (2026-09-22)

Compact card: fixed **56×56 left thumbnail** + content right + unread dot top-right (dot hidden when read). Four thumbnail states, constant footprint so no layout shift on resolve:
- loading (`!previewFetchAttempted`) → animated moving-highlight **shimmer** (`ShimmerBox`)
- loaded (`previewImageData != nil`) → cropped image
- no preview (attempted, nil) → **source-aware SF Symbol** on neutral fill (`SourceIcon.symbol(for:)` — YouTube▶/Instagram📷/LinkedIn briefcase/X bubble/… else link)
- read → whole card 0.55 opacity, no dot
Detail view keeps the **large 180pt banner image** (read mode). Fetch switched to **concurrent** (`withTaskGroup`) + `LinkPreviewFetcher` marked `nonisolated` (project defaults to MainActor isolation) with inlined URL parsing. New file `Support/CardSupport.swift` (SourceIcon + ShimmerBox). No model change, no new extension membership (all app-only).
- [x] ✅ verified on device (2026-09-22) — shimmer→resolve with no layout shift, source glyphs, large detail banner, read muting all working.
- [x] Bugfix (2026-09-22): detail view overflowed horizontally — the 180pt banner used `scaledToFill` with a flexible frame and no `.clipped()`, ballooning layout width. Fixed with single bounded `.frame(maxWidth:.infinity, height:180).clipped()` + pinned content VStack to `maxWidth:.infinity`. (Feed thumbnail unaffected — fixed 56×56 frame.)

## 5. Progress Log
- **2026-09-20** — Renamed project MyApp → AggregatorBuddy. Read spec + wireframes. Resolved all open questions. Created this plan.md.
- **2026-09-20** — Phase 0–2 complete. Project settings: bundle ID `com.nitishsharma.aggregatorbuddy`, iOS 17.0, iOS-only. Wrote data model + shared container, full main-app UI (feed/card/filter/detail/empty), theme, helpers. Used skills: `swiftdata`, `swiftui-patterns`.
  - **Blocked on local build verification:** only Command Line Tools installed here (no Xcode.app), so `xcodebuild` can't run. Code reviewed manually; fixed one real issue (CardView readDot ternary → @ViewBuilder overlay). SourceKit "macro plugin not found / cannot find Theme/Item" diagnostics are indexer noise, not compile errors.
  - **⚠️ Runtime prerequisite:** main app needs the **App Groups capability** (`group.com.nitishsharma.aggregatorbuddy`) enabled BEFORE first run, else `SharedModelContainer.shared` fatalErrors. User must add it in Xcode.
- **2026-09-20** — ✅ **Main app builds and runs** on user's machine. Phase 0–2 confirmed working end to end. No code changes were needed after review — the SourceKit diagnostics were indeed indexer noise. Ready for Phase 3 (Share Extension).
- **2026-09-20** — Phase 3 code written (Share Extension): `ShareViewController` + `ShareEntryView` + `Info.plist` + entitlements, staged in `AggregatorBuddyShareExtension/`. Used skill: `swiftui-uikit-interop`.
- **2026-09-20** — User created the extension target; Xcode used a synchronized folder group (Swift files auto-included) but reverted Info.plist to the storyboard template. With Xcode closed, fixed on disk: Info.plist → principal-class, removed storyboard, ext deployment target 27→17, added `CODE_SIGN_ENTITLEMENTS` (both configs) + entitlements membership exception. Both targets' entitlements confirmed to share `group.com.nitishsharma.aggregatorbuddy`.
- **2026-09-20** — ✅ **Phase 3 complete.** Two more gotchas fixed: (1) Xcode had overwritten `ShareViewController.swift` with its `SLComposeServiceViewController` template during target creation — rewrote with the SwiftUI-hosting version; (2) added missing `import SwiftData`. Full flow verified: Safari share → SwiftUI form → Save → item appears in app feed. **All of Phases 0–3 done and working end to end.** Next: Phase 4 acceptance-criteria verification.
- **2026-09-20** — ✅ **Phase 4 complete — Phase 1 of the app is DONE.** Code-audited all 12 criteria, fixed the detail-delete stale-ref bug, user verified every criterion (incl. delete-from-detail, tap/long-press, filters, plain-text fallback) working in the simulator. 🎉
