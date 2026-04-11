# DrawThingsStoryboard — Architecture

## Overview

DrawThingsStoryboard is a native macOS SwiftUI app (macOS 14.0+) built on strict MVVM. All state lives in `ContentView` as `@State` and flows down through `@Binding`. There is no SwiftData, no CoreData, and no global singletons beyond `StorageService.shared` and `QueueRunnerService` (held as `@StateObject` in ContentView).

Current version: **v0.7** (April 2026).

## Layer overview

```
UI (SwiftUI Views)
    ↓ @Binding
ViewModels (@MainActor ObservableObject)
    ↓ protocol
Services (DrawThingsClient, StorageService, QueueRunnerService, FountainParser, PushoverService)
    ↓
External (Draw Things via gRPC, ~/Pictures filesystem, .fountain files, Pushover API)
```

## Navigation

A three-pane `NavigationSplitView` with six sidebar sections (`AppSection`).
Sidebar order: **Models, Styles, Assets, Storyboard, Production Queue, Settings**.

| Section | Content pane | Detail pane |
|---------|-------------|-------------|
| models | ModelsBrowserView | ModelsDetailView |
| styles | StylesBrowserView | StylesDetailView |
| assets | AssetsBrowserView | AssetsDetailView |
| storyboard | StoryboardBrowserView | StoryboardDetailView |
| productionQueue | ProductionBrowserView | ProductionJobDetailView |
| settings | SettingsContentView | — |

## Toolbar

The main toolbar (right side of the title bar) shows:
1. **QueueStatusToolbarView** — live queue status (spinner + job count + estimated finish time when running)
2. **ConnectionStatusView** — Draw Things gRPC connection indicator (green/red dot)

## Data model

All models are plain Swift `Codable` structs stored as 6 JSON files in `~/Pictures/DrawThings-Storyboard/`. All generated images are stored as `<UUID>.png` in the same folder (flat structure, no subfolders).

ERD diagram: [`docs/data-model.mermaid`](docs/data-model.mermaid)

### JSON files and their structs (DataModels.swift)

```
config.json        → AppConfig
                     (image sizes, panel duration, style prompt, gRPC address/port,
                      characterTurnAround, pushoverToken, pushoverUser)

models.json        → ModelsFile
                     └── [ModelEntry]  (modelID, name, model filename, steps, guidanceScale,
                                        sampler, isImg2ImgCapable, gen times)

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
                                        styleVariants: [styleID → AssetStyleVariants])
                           └── AssetStyleVariants  (variants: [AssetVariant] (≤4),
                                                    largeImageID, approvedVariantIndex, seed)

production-log.json → ProductionLogFile
                      └── [GeneratedImageEntry]  (imageID, type, modelID, styleID,
                                                   startTime, endTime, size, seed, combinedPrompt)
```

## Draw Things integration

Communication with Draw Things runs over **gRPC** using the [euphoriacyberware-ai/DT-gRPC-Swift-Client](https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client) package.

```
DrawThingsClientProtocol
  ├── DrawThingsGRPCClient   production (configurable address:port, TLS)
  ├── DrawThingsHTTPClient   fallback   (no moodboard support)
  └── DrawThingsMockClient   previews / tests
```

### Sampler mapping

`DrawThingsGRPCClient` maps human-readable sampler names (e.g. "UniPC Trailing") to the `SamplerType` enum from the gRPC package. All 20 sampler types are supported via a static lookup table.

### Model resolution in QueueRunner

Jobs carry their own `modelID`. The QueueRunner resolves the model with this priority:
1. `job.modelID` (from the model picker active when the job was created)
2. `selectedModelID` (global fallback)
3. First model in models.json (last resort)

## Generation flow (v0.7 — fully automatic with notifications)

1. User clicks Generate button (Style, Asset, Panel) or batch button
2. A `GenerationJob` is created (carrying modelID, styleID, combined prompt)
3. `QueueRunnerService` auto-starts: picks first job, resolves model from `job.modelID`
4. Creates fresh `ImageGenerationViewModel`, sets model/steps/CFG/sampler from resolved ModelEntry
5. Generates image(s) via Draw Things gRPC, saves as `<UUID>.png`
6. Sends Pushover notification (if enabled): per-job progress + queue-complete message
7. `onJobCompleted` passes the job back to `ContentView.handleJobCompleted()`
8. QueueRunner picks next job automatically

### Step-level progress

The `generationStage` string from the gRPC client ("Generating image (step N)...") is parsed to extract the current step number. Combined with `stepsPerVariant` (from model config) and `totalVariants`, this provides a fine-grained progress bar showing e.g. step 47/140.

### Time estimation (model-aware)

- Production log records ISO8601 start/end times per generated image
- `estimatedPerImage` filters by **modelID + size** for accurate per-model estimates
- Fallback chain: log average → model.defaultGenTimeSmall/Large → hardcoded 60/180s

## Pushover notifications

`PushoverService` sends fire-and-forget HTTP POST notifications to pushover.net.
- Credentials (token + user) stored in `AppConfig` (config.json)
- Toggle in Production Queue header (persisted via @AppStorage)
- Per-job notification: item name, duration, image count, remaining jobs
- Queue-complete notification: final summary

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
│   └── Shared/Views/       # UnifiedThumbnailView, ConnectionStatusView, QueueStatusToolbarView
├── Models/                 # DataModels.swift, GenerationJob.swift, GenerationRequest/Response.swift
└── Services/
    ├── DrawThingsClient/   # Protocol + gRPC/HTTP/Mock clients
    ├── Storage/            # StorageService, StorageSetupService, StorageLoadService
    ├── QueueRunnerService.swift
    ├── PushoverService.swift
    ├── PDFExportService.swift      # panel grid export + character sheet export
    └── FountainParser.swift
```

## PDF Export (PDFExportService)

Two export modes:

| Method | Output | Trigger |
|--------|--------|---------|
| `exportWithSavePanel(panels:headerTitle:defaultFilename:)` | 2×3 grid A4, all scope panels | Storyboard Export group |
| `exportCharacterSheetsWithSavePanel(characters:defaultFilename:)` | One full-page per character (large image + name caption) | Assets Export group |

Character sheets only include characters that have a **large image** for the currently active style.
