# DrawThingsStoryboard — Architecture

## Overview

DrawThingsStoryboard is a native macOS SwiftUI app (macOS 14.0+) built on strict MVVM. All state lives in `ContentView` as `@State` and flows down through `@Binding`. There is no SwiftData, no CoreData, and no global singletons beyond `StorageService.shared`.

## Layer overview

```
UI (SwiftUI Views)
    ↓ @Binding
ViewModels (@MainActor ObservableObject)
    ↓ protocol
Services (DrawThingsClient, StorageService)
    ↓
External (Draw Things via gRPC, ~/Pictures filesystem)
```

## Navigation

A three-pane `NavigationSplitView` with six sidebar sections (`AppSection`):

| Section | Content pane | Detail pane |
|---------|-------------|-------------|
| storyboard | StoryboardBrowserView | StoryboardDetailView |
| assets | AssetsBrowserView | AssetsDetailView |
| styles | StylesBrowserView | StylesDetailView |
| models | ModelsBrowserView | ModelsDetailView |
| productionQueue | ProductionBrowserView | ProductionJobDetailView |
| settings | SettingsContentView | — |

## Data model

All models are plain Swift `Codable` structs stored as 6 JSON files in `~/Pictures/DrawThings-Storyboard/`. All generated images are stored as `<UUID>.png` in the same folder (flat structure, no subfolders).

### JSON files and their structs (DataModels.swift)

```
config.json        → AppConfig
                     (image sizes, panel duration, style prompt, shared secret)

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
                                        variant1–variant4: AssetVariant)

production-log.json → ProductionLogFile
                      └── [GeneratedImageEntry]  (imageID, type, modelID, styleID,
                                                   refs, times, seed, prompt)
```

### Image references

All image fields (`smallImageID`, `largeImageID`, variant `smallImageID`) store UUID strings that correspond to `<UUID>.png` files in the root folder.

### Seed handling

- `seed = 0` means "not yet assigned" (ungenerated)
- The app generates random seeds via `SeedHelper.randomSeed()` before sending to Draw Things
- Draw Things receives actual seed values (never 0)

## Draw Things integration

Communication with Draw Things runs over **gRPC** using the [euphoriacyberware-ai/DT-gRPC-Swift-Client](https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client) package.

```
DrawThingsClientProtocol
  ├── DrawThingsGRPCClient   production (localhost:7859, TLS)
  ├── DrawThingsHTTPClient   fallback   (localhost:7859, no moodboard)
  └── DrawThingsMockClient   previews / tests
```

`DrawThingsGRPCClient.generateImage()` accepts:
- `request` — prompt, seed, dimensions, model, steps, guidance
- `moodboardImages` — up to 3 `NSImage` passed as shuffle ControlNet hints
- `initImage` — optional canvas image for img2img (4th panel asset)

## Prompt assembly

| Job type | Combined prompt |
|----------|----------------|
| Style example | `style.style` + `config.stylePrompt` |
| Panel | `style.style` + `panel.description` |

## File storage

`StorageService.shared` writes to `~/Pictures/DrawThings-Storyboard/`.

All files are flat in the root folder:
- 6 JSON files for data
- `<UUID>.png` for all generated images

On first launch, `StorageSetupService` creates the folder and all 6 JSON files with demo data (4 characters, 4 locations, 3 styles, 1 model, 1 storyboard).

## Generation flow

1. User clicks "Generate" in a section (Styles, Assets, Storyboard)
2. A `GenerationJob` is created with `styleID`/`assetID`/`panelID` and added to `generationQueue`
3. User navigates to Production Queue, selects the job, clicks "Generate"
4. `GeneratePanel` calls `ImageGenerationViewModel.generate()` via Draw Things gRPC
5. Resulting image is saved as `<UUID>.png` via `StorageService.saveImage()`
6. `onJobCompleted` passes the job (with `savedImageIDs`) back to `ContentView.handleJobCompleted()`
7. `handleJobCompleted` writes the image UUID into the appropriate data model and persists the JSON

Currently implemented for **Styles** (image UUID → `StyleEntry.smallImageID`, persisted to `styles.json`).
