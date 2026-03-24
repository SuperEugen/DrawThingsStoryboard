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

A three-pane `NavigationSplitView` with seven sidebar sections (`AppSection`):

| Section | Content pane | Detail pane |
|---------|-------------|-------------|
| projects | ProjectsBrowserView | ProjectsDetailView |
| assets | AssetDetailPane | LibraryBrowserView |
| looks | LooksBrowserView | LooksDetailView |
| storyboard | StoryboardBrowserView | StoryboardDetailView |
| modelConfig | ModelConfigBrowserView | ModelConfigDetailView |
| productionQueue | ProductionBrowserView | ProductionJobDetailView |
| configuration | ConfigurationView | — |

## Data model

All models are plain Swift structs — value types, `Identifiable`, no persistence layer yet.

```
MockStudio
  └── MockCustomer
        └── MockEpisode
              ├── [CastingItem]   characters
              ├── [CastingItem]   locations
              └── [MockAct]
                    └── [MockSequence]
                          └── [MockScene]
                                └── [MockPanel]

CastingItem
  └── [Variant]   up to 4, isApproved / isGenerated

GenerationTemplate   (Look — style prompt)
DTModelConfig        (Draw Things model parameters)
GenerationJob        (queued/done generation task)
```

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
| Asset variant | `item.description`, `item.prompt` |
| Look example | `look.description`, `lookPromptCharacter/Location` |
| Panel | `look.description`, `lookPromptPanel`, `panel.description` |

The type-specific suffixes (`lookPromptCharacter`, `lookPromptLocation`, `lookPromptPanel`) are stored via `@AppStorage` and editable in the Configuration section.

## File storage

`StorageService.shared` writes to the macOS sandbox-safe Pictures directory:

```
~/Pictures/DrawThings-Storyboard/    dtsb-config.json
├── library/
│   ├── <studioName>/                st-config.json, st-catalog.json, <assetFileName>.png
│   │   └── <customerName>/          cu-config.json, cu-catalog.json, <assetFileName>.png
│   │       └── <episodeName>/       ep-config.json, ep-catalog.json, <assetFileName>.png
│   └── looks/                       lo-catalog.json, <lookFileName>.png
└── <episodeName>/                   pa-config.json, pa-catalog.json, <panelFileName>.png
```
Images are loaded back on demand (e.g. `loadFirstAvailableVariant(assetID:)` for panel moodboards).

---

## Persistence — Concepts

> This section captures ideas and drafts for future persistent data storage.

### Current state

All data (Studios, Episodes, Templates, ModelConfigs) lives exclusively as in-memory `@State` in `ContentView`. It is lost when the app quits. Only generated images are persisted to the filesystem.

### Goals

- Project data survives an app restart
- Multiple projects / studios can be managed
- Exchangeable format (e.g. for backup or versioning)
- Simplest possible implementation without an external database

### Plan

All *.json files need to have a version to make it possible to migrate to a newer version if necessary.

**JSON file for app-wide configs**
- ModelConfigs are stored in dtsb-config.json.
- All other Configuration data (app-wide) is also stored in dtsb-config.json.

**JSON files per project**
- One folder per project/episode in `~/Pictures/DrawThings-Storyboard/<EpisodeName>/`
- `pa-config.json` contains Studio, Customer, Episode, CharacterItems, LocationItems
- Simple, human-readable, versionable with git
- `Codable` conformance on all models is sufficient

**Additional JSON files in library**
- The *-config.json files contain all the configuration data that should persist, i.e. name, rules, preferred look etc.
- The *-catalog.json files are lists of all *.png files in the respective folders containing all metadata of all generated images in the folder. The entries are found by their filename.
- When assets are moved from one level to another (e.g. from Studio to Customer) the catalog files have to be updated accordingly (the from and the to catalog).

### Planned JSON structures

> *Concrete JSON formats will be documented here once they are defined.*

```json
// Placeholder — will be filled with concrete ideas
{
  "version": "1",
  "studio": { },
  "templates": [ ],
  "modelConfigs": [ ]
}
```

### Open questions

- Should CastingItems reference their generated variant paths in JSON?
