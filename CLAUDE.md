# DrawThingsStoryboard — Claude Context

## Project Overview
Native macOS SwiftUI app (macOS 14.0) for AI-assisted storyboard creation.
Integrates Draw Things via gRPC for image generation.
Repo: https://github.com/SuperEugen/DrawThingsStoryboard
Local: /Users/ingo/DocsMacMini/hobbies/programming/xcode/DrawThingsStoryboard
Current version: **v0.4** (April 2026)

## Architecture
- **MVVM**, strict, files under 300 lines where possible
- **NavigationSplitView** (3 panes: Sidebar / Browser / Detail)
- No SwiftData, no CoreData — all state in ContentView as @State, flows down via @Binding
- macOS Sandbox: all data in ~/Pictures/DrawThings-Storyboard/

## Sidebar Sections (AppSection) — in this order
1. assets — Character and location browser + editor
2. styles — Visual style templates (style prompts, example images)
3. models — Draw Things model configurations
4. storyboard — Act / Sequence / Scene / Panel hierarchy
5. productionQueue — Auto-processing queue + Done list
6. settings — App settings (image sizes, prompts, gRPC address/port)

## Data Storage — 6 JSON files + flat images

All data lives in `~/Pictures/DrawThings-Storyboard/` as 6 JSON files.
All generated images are `<UUID>.png` in the same folder (no subfolders).
ERD diagram: `docs/data-model.mermaid`

| File | Root struct | Contents |
|------|------------|----------|
| config.json | AppConfig | Image sizes, panel duration, style prompt, gRPC address/port |
| models.json | ModelsFile → [ModelEntry] | Model configs (filename, steps, guidance, gen times) |
| styles.json | StylesFile → [StyleEntry] | Style prompts, smallImageID, isGenerated |
| storyboards.json | StoryboardsFile → [StoryboardEntry] | Storyboards with acts/sequences/scenes/panels |
| assets.json | AssetsFile → [AssetEntry] | Characters & locations with 4 variants each |
| production-log.json | ProductionLogFile → [GeneratedImageEntry] | Log of all generated images with timestamps |

## Key Models (Models/DataModels.swift)
- **AppConfig** — Codable, Equatable. Image sizes, stylePrompt, grpcAddress, grpcPort
- **ModelEntry** — modelID, name, model (filename), steps, guidanceScale, defaultGenTimeSmall/Large
- **StyleEntry** — styleID, name, style (prompt text), smallImageID, isGenerated
- **StoryboardEntry** — name, modelID, styleID, acts[ActEntry]
- **ActEntry / SequenceEntry / SceneEntry** — name, nested children
- **PanelEntry** — panelID, name, description, cameraMovement, dialogue, duration, seed, smallImageID, largeImageID, ref1ID–ref4ID
- **AssetEntry** — assetID, name, type, subType, description, variant1–4 (AssetVariant), smallImageID, largeImageID
- **AssetVariant** — smallImageID, seed, isApproved
- **GenerationJob** — id, itemName, jobType, size, styleName, seed, dimensions, combinedPrompt, styleID/assetID/panelID, savedImageIDs
- **GeneratedImageEntry** — imageID, type, modelID, styleID, startTime, endTime, size, seed, combinedPrompt

## Seed Handling
- `seed = 0` means "not yet assigned" (ungenerated)
- App generates random seeds via `SeedHelper.randomSeed()` (1...999_999)
- Draw Things never receives seed 0
- Large image generation copies seed from approved variant (#6)

## Services
- **DrawThingsGRPCClient** — production client, configurable address/port, TLS on
- **DrawThingsHTTPClient** — fallback HTTP (no moodboard)
- **DrawThingsMockClient** — previews / tests
- **StorageService.shared** — root URL, read/write JSON, save/load images by UUID
- **StorageSetupService** — creates 6 JSON files with demo data on first launch
- **StorageLoadService** — reads all 6 JSONs into AppState, individual save methods per file
- **QueueRunnerService** — @MainActor ObservableObject, auto-processes queue sequentially
- **FountainParser** — parses .fountain screenplay files into Act/Sequence/Scene structure

## Generation Flow (v0.4 — fully automatic)
1. User clicks Generate button (Style, Asset, Panel) or batch button
2. GenerationJob created, added to generationQueue
3. QueueRunnerService auto-starts: picks first job, creates fresh ImageGenerationViewModel
4. Generates image(s) via Draw Things gRPC, saves as <UUID>.png
5. onJobCompleted → ContentView.handleJobCompleted()
6. handleJobCompleted writes UUIDs into data model + production-log.json, persists all JSONs
7. QueueRunner picks next job automatically (sequential processing)
8. Stop button removes all waiting jobs (running job finishes)

### Job types and what gets wired back:
- **generateStyle** → StyleEntry.smallImageID + isGenerated
- **generateAsset (small)** → fills next empty AssetEntry.variant1–4 slots
- **generateAsset (large)** → AssetEntry.largeImageID (uses approved variant seed)
- **generatePanel (small)** → PanelEntry.smallImageID
- **generatePanel (large)** → PanelEntry.largeImageID

### Time estimation:
- Production log records start/end times per image
- Estimated duration = average of last 3 log entries per size (small/large)
- Fallback: 60s small, 180s large

## Fountain Import
- FountainParser: `#` → Act, `##` → Sequence, `###` → Scene (each with one empty panel)
- Strips Beat metadata blocks (`/* ... */`)
- Import button in StoryboardBrowserView header (NSOpenPanel for .fountain files)
- Replaces current storyboard acts + name, persists to storyboards.json

## File Structure
```
DrawThingsStoryboard/
├── App/                    # DrawThingsStoryboardApp, ContentView, SidebarView, AppSection, AppCommands
├── Features/
│   ├── Assets/             # AssetsBrowserView, AssetsDetailView
│   ├── Styles/             # StylesBrowserView, StylesDetailView
│   ├── Models/             # ModelsBrowserView, ModelsDetailView
│   ├── Storyboard/Views/   # StoryboardBrowserView, StoryboardDetailView
│   ├── ProductionQueue/    # ProductionBrowserView, ProductionJobDetailView
│   ├── Settings/           # SettingsView (Cmd+,), SettingsContentView (in-app)
│   ├── ImageGeneration/    # ImageGenerationViewModel
│   └── Shared/Views/       # UnifiedThumbnailView, ConnectionStatusView, sectionLabel()
├── Models/                 # DataModels.swift, GenerationJob.swift, GenerationRequest/Response.swift
└── Services/
    ├── DrawThingsClient/   # Protocol + gRPC/HTTP/Mock clients
    ├── Storage/            # StorageService, StorageSetupService, StorageLoadService
    ├── QueueRunnerService.swift
    └── FountainParser.swift
```

## Draw Things Connection
- Protocol: gRPC, configurable address + port (default localhost:7859), TLS enabled
- gRPC package: https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client
- Connection status indicator in toolbar via NWConnection TCP check
- Model filename must match exactly as shown in Draw Things

## Development Workflow
- Claude writes / commits Swift files to GitHub via MCP
- Ingo pulls via terminal: `git stash && git pull && git stash drop`
- Builds in Xcode (⌘B)
- On conflicts: local Xcode-modified files (e.g. .pbxproj) need stash/drop
- `github:push_files` preferred for multi-file commits (no SHA needed)
- `github:create_or_update_file` requires current SHA from `github:get_file_contents`
- Always read files before editing to confirm exact content
- Closing issues: always `add_issue_comment` first, then `update_issue` with state closed

## Prompt Assembly
- **Style example**: style.style + config.stylePrompt
- **Asset**: style.style + asset.description
- **Panel**: style.style + panel.description + panel.cameraMovement

## UnifiedThumbnailView
Used everywhere for consistent thumbnails. Supports real images via `imageID` parameter.
Item types:
- `.character(subType:)` — blue, person icon
- `.location(subType:)` — green, house/map icon
- `.style` — orange, paintpalette icon
- `.panel` — yellow, video icon
- `.model` — purple, gearshape icon

Size modes: `.standard` (288×160), `.header` (full width×160), `.compact` (80×45)

## Known Swift Patterns & Pitfalls
- Type-checker timeout → split body into private structs with @Binding
- `AppConfig` must be `Equatable` for `.onChange(of:)` to work
- `ForEach(0..<4)` with variable array length → always guard with `if idx < array.count`
- `let` parameters are not tracked reactively by SwiftUI → use `@Binding`
- Duplicate Swift files (old + new name) cause Xcode "duplicate symbol" errors → `git rm` old files
- Job completion must always call `onJobCompleted` even on error, otherwise jobs hang
- Fresh ImageGenerationViewModel per job in QueueRunner (no accumulated state)
- Synchronous `isBusy` flag in QueueRunner prevents race condition re-entry
- `import UniformTypeIdentifiers` required for NSOpenPanel with UTType

## Mermaid ERD Pitfalls
- `STYLE` is a reserved word in Mermaid → use `STYLEENTRY` as entity name
- Entity names must not contain underscores → use `GENERATEDIMAGE` not `GENERATED_IMAGE`
- Only `string` and `int` are reliable types → avoid `bool`, `float`, `double`
- No frontmatter (`---title---`) in `.mermaid` files for GitHub rendering
- Relationship labels must not contain hyphens → use `variants` not `has-4-of`
