# DrawThingsStoryboard — Claude Context

## Project Overview
Native macOS SwiftUI app (macOS 14.0) for AI-assisted storyboard creation.
Integrates Draw Things via gRPC for image generation.
Repo: https://github.com/SuperEugen/DrawThingsStoryboard
Local: /Users/ingo/DocsMacMini/hobbies/programming/xcode/DrawThingsStoryboard

## Architecture
- **MVVM**, strict, files under 300 lines
- **NavigationSplitView** (3 panes: Sidebar / Browser / Detail)
- No SwiftData, no CoreData — all in-memory state in ContentView
- macOS Sandbox: images are stored in ~/Pictures/DrawThings-Storyboard/

## Sidebar Sections (AppSection)
1. projects — Studio → Customer → Episode (ProjectsDetailView)
2. assets — CastingItem Browser + Library
3. looks — GenerationTemplate (style prompts)
4. storyboard — Act / Sequence / Scene / Panel hierarchy
5. modelConfig — DTModelConfig (Draw Things model parameters)
6. productionQueue — Queue + Done list
7. configuration — Settings (sizes, look prompts, shared secret)

## Key Models (Models/)
- **MockStudio / MockCustomer / MockEpisode** — hierarchy with preferredLookID, rules
- **CastingItem** — character or location, with variants
- **Variant** — isApproved, isGenerated, label
- **GenerationTemplate** — Look (name, description = style prompt, itemType, lookStatus)
- **DTModelConfig** — name, model (filename), steps, guidanceScale
- **GenerationJob** — full job with attachedAssets, queuedAt, startedAt, completedAt
- **MockPanel** — smallPanelAvailable, largePanelAvailable, attachedAssetIDs
- **MockAct / Scene / Sequence / Panel** — storyboard hierarchy

## Services
- **DrawThingsGRPCClient** — production client, port 7859, TLS on
  - generateImage(request:moodboardImages:initImage:onProgress:)
  - Moodboard = shuffle ControlNet hints, initImage = canvas (img2img)
- **DrawThingsHTTPClient** — fallback HTTP, port 7859 (no moodboard)
- **DrawThingsMockClient** — previews / tests
- **StorageService.shared** — ~/Pictures/DrawThings-Storyboard/
  - library/assets/<assetID>_v<n>.png
  - library/examples/<lookName>.png
  - <EpisodeName>/panels/<panelID>.png

## Draw Things Connection
- Protocol: gRPC, Port: 7859, TLS: enabled
- gRPC package: https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client
- Package added via Xcode → File → Add Package Dependencies
- Model filename must match exactly as shown in Draw Things

## Development Workflow
- Claude writes / commits Swift files to GitHub
- Ingo pulls via terminal: `git pull`
- Builds in Xcode (⌘+B)
- On Xcode dialog: choose "Use Version on Disk"
- On conflicts: `git stash && git pull && git stash drop`

## AppStorage Keys (persistent)
- dts.previewVariantWidth/Height — small image size (default 576×320)
- dts.finalWidth/Height — large image size (default 1920×1080)
- dts.lookPromptCharacter — prompt suffix for character looks
- dts.lookPromptLocation — prompt suffix for location looks
- dts.lookPromptPanel — prompt suffix for panel looks

## Prompt Assembly
- **Asset/Variant**: item.description + item.prompt (from CastingItem)
- **Look Example**: look.description + lookPromptCharacter/Location
- **Panel**: look.description + lookPromptPanel + panel.description
- **Panel Assets**: up to 3 → moodboardImages (shuffle hints), 4th → initImage

## Known Swift Patterns & Pitfalls
- Type-checker timeout → split body into private structs
- `ModelConfiguration` (SwiftData) vs `DTModelConfig` (our class) — hence DTModelConfig
- `Hashable` on structs with CastingItem properties fails → use Identifiable only
- `ForEach(0..<4)` with variable array length → always guard with `if idx < array.count`
- `let` parameters are not tracked reactively by SwiftUI → use `@Binding`
- `variantsAvailable` is computed (from variants) — cannot be set directly
- Desktop Commander `sudo` is blocked → xcode-select cannot be changed via terminal
