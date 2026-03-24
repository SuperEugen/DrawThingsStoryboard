# DrawThingsStoryboard — Claude Context

## Projekt-Überblick
Native macOS SwiftUI-App (macOS 14.0) zur KI-gestützten Storyboard-Erstellung.
Integriert Draw Things über gRPC für Bildgenerierung.
Repo: https://github.com/SuperEugen/DrawThingsStoryboard
Lokal: /Users/ingo/DocsMacMini/hobbies/programming/xcode/DrawThingsStoryboard

## Architektur
- **MVVM**, strict, Dateien unter 300 Zeilen
- **NavigationSplitView** (3 Panes: Sidebar / Browser / Detail)
- Kein SwiftData, kein CoreData — alles in-memory State in ContentView
- macOS Sandbox: Bilder werden in ~/Pictures/DrawThings-Storyboard/ gespeichert

## Sidebar-Sections (AppSection)
1. projects — Studio → Customer → Episode (BriefingDetailView)
2. assets — CastingItem Browser + Library
3. looks — GenerationTemplate (Style-Prompts)
4. storyboard — Akt/Sequenz/Szene/Panel Hierarchie
5. modelConfig — DTModelConfig (Draw Things Modell-Parameter)
6. productionQueue — Queue + Done-Liste
7. configuration — Einstellungen (Größen, Look-Prompts, Shared Secret)

## Wichtige Modelle (Models/)
- **MockStudio / MockCustomer / MockEpisode** — Hierarchie mit preferredLookID, rules
- **CastingItem** — Character oder Location, mit Variants
- **Variant** — isApproved, isGenerated, label
- **GenerationTemplate** — Look (name, description=style-prompt, itemType, lookStatus)
- **DTModelConfig** — name, model (filename), steps, guidanceScale
- **GenerationJob** — vollständiger Job mit attachedAssets, queuedAt, startedAt, completedAt
- **MockPanel** — smallPanelAvailable, largePanelAvailable, attachedAssetIDs
- **MockAct/Scene/Sequence/Panel** — Storyboard-Hierarchie

## Services
- **DrawThingsGRPCClient** — Production-Client, Port 7859, TLS on
  - generateImage(request:moodboardImages:initImage:onProgress:)
  - Moodboard = shuffle ControlNet hints, initImage = Canvas (img2img)
- **DrawThingsHTTPClient** — Fallback HTTP, Port 7859 (kein Moodboard)
- **DrawThingsMockClient** — Previews/Tests
- **StorageService.shared** — ~/Pictures/DrawThings-Storyboard/
  - library/assets/<assetID>_v<n>.png
  - library/examples/<lookName>.png
  - <EpisodeName>/panels/<panelID>.png

## Draw Things Verbindung
- Protocol: gRPC, Port: 7859, TLS: enabled
- gRPC-Package: https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client
- Package wurde via Xcode → File → Add Package Dependencies hinzugefügt
- Modell-Dateiname muss exakt wie in Draw Things angegeben werden

## Workflow: Entwicklung
- Claude schreibt/committed Swift-Files zu GitHub
- Ingo pullt via Terminal: `git pull`
- Baut in Xcode (⌘+B)
- Bei Xcode-Dialog "Use Version on Disk" wählen
- Bei Konflikten: `git stash && git pull && git stash drop`

## AppStorage Keys (persistent)
- dts.previewVariantWidth/Height — Small image size (default 576×320)
- dts.finalWidth/Height — Large image size (default 1920×1080)
- dts.lookPromptCharacter — Prompt-Suffix für Character-Looks
- dts.lookPromptLocation — Prompt-Suffix für Location-Looks
- dts.lookPromptPanel — Prompt-Suffix für Panel-Looks

## Prompt-Zusammensetzung
- **Asset/Variant**: item.description + item.prompt (aus CastingItem)
- **Look Example**: look.description + lookPromptCharacter/Location
- **Panel**: look.description + lookPromptPanel + panel.description
- **Panel Assets**: bis zu 3 → moodboardImages (shuffle hints), 4. → initImage

## bekannte Swift-Patterns & Fallstricke
- Type-Checker Timeout → body in private structs aufteilen
- `ModelConfiguration` (SwiftData) vs `DTModelConfig` (unsere Klasse) — deshalb DTModelConfig
- `Hashable` auf Structs mit CastingItem-Properties schlägt fehl → nur Identifiable
- `ForEach(0..<4)` mit varianter Array-Länge → immer `if idx < array.count` guarden
- `let`-Parameter werden von SwiftUI nicht reactive getrackt → `@Binding` verwenden
- `variantsAvailable` ist computed (aus variants) — kann nicht direkt gesetzt werden
- Desktop Commander `sudo` ist geblockt → xcode-select nicht via Terminal umstellbar
