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
| projects | BriefingBrowserView | BriefingDetailView |
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
~/Pictures/DrawThings-Storyboard/
├── library/
│   ├── assets/     <assetID>_v<n>.png
│   └── examples/   <lookName>.png
└── <EpisodeName>/
    └── panels/     <panelID>.png
```

Images are loaded back on demand (e.g. `loadFirstAvailableVariant(assetID:)` for panel moodboards).

---

## Persistence — Konzept und offene Fragen

> Dieser Abschnitt ist für Ideen und Entwürfe zur künftigen persistenten Datenspeicherung.

### Aktueller Stand

Alle Daten (Studios, Episodes, Templates, ModelConfigs) leben ausschließlich als in-memory `@State` in `ContentView`. Sie gehen beim Beenden der App verloren. Nur generierte Bilder werden persistent auf dem Filesystem gespeichert.

### Ziele

- Projektdaten überleben einen App-Neustart
- Mehrere Projekte / Studios verwaltbar
- Austauschbares Format (z.B. für Backup oder Versionierung)
- Möglichst einfache Implementierung ohne externe Datenbank

### Optionen

**Option A — JSON-Dateien pro Projekt**
- Ein Ordner pro Projekt/Episode in `~/Pictures/DrawThings-Storyboard/<EpisodeName>/`
- `project.json` enthält Studio, Customer, Episode, CastingItems, Templates, ModelConfigs
- Einfach, menschenlesbar, versionierbar mit git
- `Codable` auf allen Modellen genügt

**Option B — SwiftData**
- Automatische Persistenz, CloudKit-Sync möglich
- Erfordert `@Model`-Umbau aller Structs auf Klassen
- Mehr Aufwand, dafür native macOS-Integration

**Option C — Single JSON-Datei**
- `~/.config/DrawThingsStoryboard/data.json`
- Alles in einer Datei, einfachstes Encoding
- Skaliert nicht gut bei großen Projekten

### Geplante JSON-Strukturen

> *Hier werden die konkreten JSON-Formate dokumentiert sobald sie festgelegt sind.*

```json
// Platzhalter — wird mit konkreten Ideen gefüllt
{
  "version": "1",
  "studio": { },
  "templates": [ ],
  "modelConfigs": [ ]
}
```

### Offene Fragen

- Welche Option (A/B/C) wird bevorzugt?
- Sollen ModelConfigs global (App-weit) oder pro Projekt gespeichert werden?
- Sollen CastingItems mit ihren generierten Variant-Pfaden im JSON referenziert werden?
- Versionierung des JSON-Formats (Migration bei Schema-Änderungen)?
