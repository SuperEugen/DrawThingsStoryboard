# DrawThingsStoryboard — Architecture

## Overview

DrawThingsStoryboard is a native macOS SwiftUI app (macOS 14.0+) built on strict MVVM. All state lives in `ContentView` as `@State` and flows down through `@Binding`. There is no SwiftData, no CoreData, and no global singletons beyond `StorageService.shared` and `QueueRunnerService` (held as `@StateObject` in ContentView).

Current version: **v0.4** (April 2026).

## Layer overview

```
UI (SwiftUI Views)
    ↓ @Binding
ViewModels (@MainActor ObservableObject)
    ↓ protocol
Services (DrawThingsClient, StorageService, QueueRunnerService, FountainParser)
    ↓
External (Draw Things via gRPC, ~/Pictures filesystem, .fountain files)
```

## Navigation

A three-pane `NavigationSplitView` with six sidebar sections (`AppSection`).
Sidebar order: Assets, Styles, Models, **Storyboard**, Production Queue, Settings.

| Section | Content pane | Detail pane |
|---------|-------------|-------------|
| assets | AssetsBrowserView | AssetsDetailView |
| styles | StylesBrowserView | StylesDetailView |
| models | ModelsBrowserView | ModelsDetailView |
| storyboard | StoryboardBrowserView | StoryboardDetailView |
| productionQueue | ProductionBrowserView | ProductionJobDetailView |
| settings | SettingsContentView | — |

## Data model

All models are plain Swift `Codable` structs stored as 6 JSON files in `~/Pictures/DrawThings-Storyboard/`. All generated images are stored as `<UUID>.png` in the same folder (flat structure, no subfolders).

ERD diagram: [`docs/data-model.mermaid`](docs/data-model.mermaid)

### JSON files and their structs (DataModels.swift)

```
config.json        → AppConfig
                     (image sizes, panel duration, style prompt, gRPC address/port)

models.json        → ModelsFile
                     └── [ModelEntry]  (modelID, name, model filename, steps, guidanceScale, gen times)

styles.json        → StylesFile
                     └── [StyleEntry]  (styleID, name, style prompt, smallImageID, isGenerated)

storyboards.json   → StoryboardsFile
                     └── [StoryboardEntry]  (name, modelID, styleID)
                           └── [ActEntry]
                                 └── [SequenceEntry]
                                       └── [SceneEntry]
                                             └── [PanelEntry]  (panelID, description, dialogue,
                                                                cameraMovement, duration, seed,
                                                                smallImageID, largeImageID,
                                                                ref1ID–ref4ID)

assets.json        → AssetsFile
                     └── [AssetEntry]  (assetID, name, type, subType, description,
                                        smallImageID, largeImageID, seed,
                                        variant1–4: AssetVariant)

production-log.json → ProductionLogFile
                      └── [GeneratedImageEntry]  (imageID, type, modelID, styleID,
                                                   startTime, endTime, size, seed, combinedPrompt)
```

### Image references

All image fields (`smallImageID`, `largeImageID`, variant `smallImageID`) store UUID strings that correspond to `<UUID>.png` files in the root folder.

### Seed handling

- `seed = 0` means "not yet assigned" (ungenerated)
- The app generates random seeds via `SeedHelper.randomSeed()` before sending to Draw Things
- Draw Things receives actual seed values (never 0)
- Large image generation copies the seed from the approved variant

## Draw Things integration

Communication with Draw Things runs over **gRPC** using the [euphoriacyberware-ai/DT-gRPC-Swift-Client](https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client) package.

```
DrawThingsClientProtocol
  ├── DrawThingsGRPCClient   production (configurable address:port, TLS)
  ├── DrawThingsHTTPClient   fallback   (no moodboard support)
  └── DrawThingsMockClient   previews / tests
```

Connection status is shown in the toolbar via `ConnectionStatusView` using `NWConnection` TCP check.

## Generation flow (v0.4 — fully automatic)

1. User clicks Generate button (Style, Asset, Panel) or batch button ("Generate all Variants", "Generate all Large Images")
2. A `GenerationJob` is created and added to `generationQueue`
3. `QueueRunnerService` auto-starts: picks first job, creates a **fresh** `ImageGenerationViewModel`
4. Generates image(s) via Draw Things gRPC, saves as `<UUID>.png`
5. `onJobCompleted` passes the job back to `ContentView.handleJobCompleted()`
6. `handleJobCompleted` writes the image UUID into the data model, writes to production-log.json, persists all relevant JSONs
7. QueueRunner picks next job automatically
8. Stop button removes all waiting jobs (running job finishes normally)

### Job completion wiring:

| Job type | Size | What gets updated |
|----------|------|------------------|
| generateStyle | small | StyleEntry.smallImageID + isGenerated |
| generateAsset | small | Next empty AssetEntry.variant1–4.smallImageID |
| generateAsset | large | AssetEntry.largeImageID (uses approved variant seed) |
| generatePanel | small | PanelEntry.smallImageID |
| generatePanel | large | PanelEntry.largeImageID |

### Time estimation:
- Production log records ISO8601 start/end times per generated image
- Estimated duration = average of last 3 log entries matching the size (small/large)
- Fallback when no log data: 60s for small, 180s for large

## Prompt assembly

| Job type | Combined prompt |
|----------|----------------|
| Style example | `style.style` + `config.stylePrompt` |
| Asset | `style.style` + `asset.description` |
| Panel | `style.style` + `panel.description` + `panel.cameraMovement` |

## Fountain import

`FountainParser` (in Services/) parses `.fountain` screenplay files:
- `#` → ActEntry
- `##` → SequenceEntry
- `###` → SceneEntry (each scene gets one empty PanelEntry)
- Beat metadata blocks (`/* ... */`) are stripped
- Storyboard name derived from filename
- Import button in StoryboardBrowserView header, uses NSOpenPanel

## File storage

`StorageService.shared` writes to `~/Pictures/DrawThings-Storyboard/`.

All files are flat in the root folder:
- 6 JSON files for data
- `<UUID>.png` for all generated images

On first launch, `StorageSetupService` creates the folder and all 6 JSON files with demo data (4 characters, 4 locations, 3 styles, 1 model, 1 storyboard).

## File structure

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
├── Services/
│   ├── DrawThingsClient/   # Protocol + gRPC/HTTP/Mock clients
│   ├── Storage/            # StorageService, StorageSetupService, StorageLoadService
│   ├── QueueRunnerService.swift
│   └── FountainParser.swift
└── docs/
    └── data-model.mermaid  # ERD of all 6 JSON files (renders on GitHub)
```
