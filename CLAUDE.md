# DrawThingsStoryboard — Claude Context

## Project Overview
Native macOS SwiftUI app (macOS 14.0) for AI-assisted storyboard creation.
Integrates Draw Things via gRPC for image generation.
Repo: https://github.com/SuperEugen/DrawThingsStoryboard
Local: /Users/ingo/DocsMacMini/hobbies/programming/xcode/DrawThingsStoryboard

## Architecture
- **MVVM**, strict, files under 300 lines where possible
- **NavigationSplitView** (3 panes: Sidebar / Browser / Detail)
- No SwiftData, no CoreData — all state in ContentView as @State, flows down via @Binding
- macOS Sandbox: all data in ~/Pictures/DrawThings-Storyboard/

## Sidebar Sections (AppSection)
1. storyboard — Act / Sequence / Scene / Panel hierarchy
2. assets — Character and location browser + editor
3. styles — Visual style templates (style prompts, example images)
4. models — Draw Things model configurations
5. productionQueue — Queue + Done list with generation
6. settings — App settings (image sizes, prompts, shared secret)

## Data Storage — 6 JSON files + flat images

All data lives in `~/Pictures/DrawThings-Storyboard/` as 6 JSON files.
All generated images are `<UUID>.png` in the same folder (no subfolders).

| File | Root struct | Contents |
|------|------------|----------|
| config.json | AppConfig | Image sizes, panel duration, style prompt, shared secret |
| models.json | ModelsFile → [ModelEntry] | Model configs (filename, steps, guidance, gen times) |
| styles.json | StylesFile → [StyleEntry] | Style prompts, smallImageID, isGenerated |
| storyboards.json | StoryboardsFile → [StoryboardEntry] | Storyboards with acts/sequences/scenes/panels |
| assets.json | AssetsFile → [AssetEntry] | Characters & locations with 4 variants each |
| production-log.json | ProductionLogFile → [GeneratedImageEntry] | Log of generated images |

## Key Models (Models/DataModels.swift)
- **AppConfig** — Codable, Equatable. Image sizes, stylePrompt, sharedSecret, defaultPanelDuration
- **ModelEntry** — modelID, name, model (filename), steps, guidanceScale, defaultGenTimeSmall/Large
- **StyleEntry** — styleID, name, style (prompt text), smallImageID, isGenerated
- **StoryboardEntry** — name, modelID, styleID, acts[ActEntry]
- **ActEntry / SequenceEntry / SceneEntry** — name, nested children
- **PanelEntry** — panelID, name, description, cameraMovement, dialogue, duration, seed, smallImageID, largeImageID, ref1ID–ref4ID
- **AssetEntry** — assetID, name, type ("character"/"location"), subType ("male"/"female"/"interior"/"exterior"), description, variant1–variant4 (AssetVariant), smallImageID, largeImageID
- **AssetVariant** — smallImageID, seed, isApproved
- **GenerationJob** — id, itemName, jobType, size, styleName, seed, dimensions, combinedPrompt, styleID/assetID/panelID, savedImageIDs

## Seed Handling
- `seed = 0` means "not yet assigned" (ungenerated)
- App generates random seeds via `SeedHelper.randomSeed()` (1...999_999) before sending to Draw Things
- Draw Things never receives seed 0

## Services
- **DrawThingsGRPCClient** — production client, port 7859, TLS on
  - generateImage(request:moodboardImages:initImage:onProgress:)
  - Moodboard = shuffle ControlNet hints, initImage = canvas (img2img)
- **DrawThingsHTTPClient** — fallback HTTP, port 7859 (no moodboard)
- **DrawThingsMockClient** — previews / tests
- **StorageService.shared** — root URL, read/write JSON, save/load images by UUID
- **StorageSetupService** — creates 6 JSON files with demo data on first launch
- **StorageLoadService** — reads all 6 JSONs into AppState, individual save methods per file

## Generation Flow
1. User clicks "Generate Example" (Style) or future generate buttons (Asset, Panel)
2. GenerationJob created with styleID/assetID/panelID, added to generationQueue
3. In Production Queue detail, user clicks "Generate" button
4. GeneratePanel calls ImageGenerationViewModel.generate() → Draw Things gRPC
5. Image saved as <UUID>.png, UUID stored in job.savedImageIDs
6. onJobCompleted → ContentView.handleJobCompleted()
7. handleJobCompleted writes UUID into data model (e.g. StyleEntry.smallImageID) and persists JSON

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
│   └── Shared/Views/       # UnifiedThumbnailView, sectionLabel()
├── Models/                 # DataModels.swift, GenerationJob.swift, GenerationRequest/Response.swift
└── Services/
    ├── DrawThingsClient/   # Protocol + gRPC/HTTP/Mock clients
    └── Storage/            # StorageService, StorageSetupService, StorageLoadService
```

## Draw Things Connection
- Protocol: gRPC, Port: 7859, TLS: enabled
- gRPC package: https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client
- Package added via Xcode → File → Add Package Dependencies
- Model filename must match exactly as shown in Draw Things

## Development Workflow
- Claude writes / commits Swift files to GitHub via MCP
- Ingo pulls via terminal: `git pull` (pull.rebase = true)
- Builds in Xcode (⌘B)
- On Xcode dialog: choose "Use Version on Disk"
- On conflicts: `git stash && git pull && git stash drop`
- Local changes should be committed and pushed BEFORE pulling
- `github:push_files` preferred for multi-file commits (no SHA needed, but cannot delete files)
- `github:create_or_update_file` requires current SHA from `github:get_file_contents`
- Always read files before editing to confirm exact content

## Prompt Assembly
- **Style example**: style.style + config.stylePrompt
- **Panel**: style.style + panel.description

## UnifiedThumbnailView
Used everywhere for consistent thumbnails. Item types:
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
- Desktop Commander `sudo` is blocked
- Duplicate Swift files (old + new name) cause Xcode "duplicate symbol" errors → `git rm` old files
