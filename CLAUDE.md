# DrawThingsStoryboard — Claude Context

## Project Overview
Native macOS SwiftUI app (macOS 14.0) for AI-assisted storyboard creation.
Integrates Draw Things via gRPC for image generation.
GitHub-Repo: https://github.com/SuperEugen/DrawThingsStoryboard
Local: /Users/ingo/DocsMacMini/hobbies/programming/xcode/DrawThingsStoryboard
Data (Runtime): /Users/ingo/Pictures/DrawThings-Storyboard/
Xcode-Build: /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild
Current version: **v0.7** (April 2026)

## Architecture
- **MVVM**, strict, files under 300 lines where possible
- **NavigationSplitView** (3 panes: Sidebar / Browser / Detail)
- No SwiftData, no CoreData — all state in ContentView as @State, flows down via @Binding
- macOS Sandbox: all data in ~/Pictures/DrawThings-Storyboard/

## Sidebar Sections (AppSection) — in this order
1. models — Draw Things model configurations (sampler, steps, CFG, img2img)
2. styles — Visual style templates (style prompts, example images)
3. assets — Character and location browser + editor
4. storyboard — Act / Sequence / Scene / Panel hierarchy
5. productionQueue — Auto-processing queue + Done list + Pushover notifications
6. settings — App settings (image sizes, prompts, gRPC, Pushover credentials)

## Toolbar
- **QueueStatusToolbarView** — live queue status (spinner, job count, estimated finish)
- **ConnectionStatusView** — gRPC connection indicator

## Data Storage — 6 JSON files + flat images

All data lives in `~/Pictures/DrawThings-Storyboard/` as 6 JSON files.
All generated images are `<UUID>.png` in the same folder (no subfolders).

| File | Root struct | Contents |
|------|------------|----------|
| config.json | AppConfig | Image sizes, panel duration, style prompt, gRPC address/port, characterTurnAround, pushoverToken, pushoverUser |
| models.json | ModelsFile → [ModelEntry] | Model configs (filename, steps, guidance, sampler, isImg2ImgCapable, gen times) |
| styles.json | StylesFile → [StyleEntry] | Style prompts, smallImageID, isGenerated |
| storyboards.json | StoryboardsFile → [StoryboardEntry] | Storyboards with acts/sequences/scenes/panels |
| assets.json | AssetsFile → [AssetEntry] | Characters & locations with 4 variants each |
| production-log.json | ProductionLogFile → [GeneratedImageEntry] | Log of all generated images with timestamps |

## Key Models (Models/DataModels.swift)
- **AppConfig** — Codable, Equatable. Image sizes, stylePrompt, grpcAddress, grpcPort, characterTurnAround, pushoverToken, pushoverUser
- **ModelEntry** — modelID, name, model (filename), steps, guidanceScale, sampler, isImg2ImgCapable, defaultGenTimeSmall/Large
- **StyleEntry** — styleID, name, style (prompt text), smallImageID, isGenerated
- **StoryboardEntry** — name, modelID, styleID, acts[ActEntry]
- **PanelEntry** — panelID, name, description, cameraMovement, dialogue, duration, seed, smallImageID, largeImageID, ref1ID–ref4ID
- **AssetEntry** — assetID, name, type, subType, description, styleVariants: [styleID: AssetStyleVariants]
- **AssetStyleVariants** — variants: [AssetVariant] (up to 4), largeImageID, approvedVariantIndex, seed
- **GenerationJob** — id, itemName, jobType, size, styleName, modelID, seed, dimensions, combinedPrompt, styleID/assetID/panelID, initImageID, moodboardImageIDs, savedImageIDs
- **GeneratedImageEntry** — imageID, type, modelID, styleID, startTime, endTime, size, seed, combinedPrompt

## Services
- **DrawThingsGRPCClient** — production client, configurable address/port, TLS on. Maps sampler strings to SamplerType enum (all 20 types).
- **DrawThingsHTTPClient** — fallback HTTP (no moodboard)
- **DrawThingsMockClient** — previews / tests
- **StorageService.shared** — root URL, read/write JSON, save/load images by UUID
- **StorageSetupService** — creates 6 JSON files with demo data on first launch (2 models, 3 styles, 8 assets)
- **StorageLoadService** — reads all 6 JSONs into AppState, individual save methods per file
- **QueueRunnerService** — @MainActor ObservableObject, auto-processes queue. Resolves model from job.modelID. Publishes step-level progress. Sends Pushover notifications.
- **PushoverService** — fire-and-forget HTTP POST to pushover.net API
- **PDFExportService** — exports panels as 2×3 grid PDF (A4); exports character sheets (one full-page per character with large image + name caption)
- **FountainParser** — parses .fountain screenplay files into Act/Sequence/Scene structure

## Generation Flow (v0.7 — model-aware, with notifications)
1. User clicks Generate button or batch button
2. GenerationJob created with modelID from active model picker
3. QueueRunnerService auto-starts: resolves model from `job.modelID` (not global state)
4. Creates fresh ImageGenerationViewModel, sets model/steps/CFG/sampler
5. Generates image(s) via Draw Things gRPC, saves as <UUID>.png
6. Sends Pushover notification if enabled (per-job + queue-complete)
7. onJobCompleted → ContentView.handleJobCompleted()
8. QueueRunner picks next job automatically

### Model resolution priority:
1. `job.modelID` (from model picker when job was created)
2. `selectedModelID` (global fallback)
3. First model in models.json (last resort)

### Step-level progress:
- Parses step number from gRPC generationStage string ("step N")
- `globalStep = currentVariant × stepsPerVariant + currentStep`
- Progress bar shows e.g. 47/140 for 4 variants × 35 steps

### Time estimation (model-aware):
- Filters production log by **modelID + size** (not just size)
- Fallback chain: log average → model.defaultGenTimeSmall/Large → hardcoded 60/180s

## Sampler Mapping
`DrawThingsGRPCClient.samplerType(from:)` maps strings to SamplerType enum:
- "UniPC Trailing" → `.unipctrailing`
- "DPM++ 2M Karras" → `.dpmpp2mkarras`
- All 20 Draw Things sampler types supported
- Case-insensitive fallback, defaults to `.dpmpp2mkarras`

## Pushover Notifications
- Credentials: `config.pushoverToken` + `config.pushoverUser` (in Settings as SecureField)
- Toggle: `@AppStorage("notificationsEnabled")` in ContentView, switch in PQ header
- Per-job: "🎬 {name} done — {duration}, {count} img. {remaining} job(s) remaining."
- Queue done: "✅ Queue finished — {name} done ({duration}). Queue complete!"

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
│   └── Shared/Views/       # UnifiedThumbnailView, ConnectionStatusView, QueueStatusToolbarView
├── Models/                 # DataModels.swift, GenerationJob.swift, GenerationRequest/Response.swift
└── Services/
    ├── DrawThingsClient/   # Protocol + gRPC/HTTP/Mock clients (with sampler mapping)
    ├── Storage/            # StorageService, StorageSetupService, StorageLoadService
    ├── QueueRunnerService.swift
    ├── PushoverService.swift
    ├── PDFExportService.swift
    └── FountainParser.swift
```

## Development Workflow
- Claude writes / commits Swift files to GitHub via MCP
- Ingo pulls via terminal: `git stash && git pull && git stash drop`
- Builds in Xcode (⌘B)
- `github:push_files` preferred for multi-file commits (no SHA needed)
- `github:create_or_update_file` requires current SHA from `github:get_file_contents`
- Closing issues: always `add_issue_comment` first, then `update_issue` with state closed
- `github:push_files` cannot delete files; deletions must be done locally with `git rm`

## Build via Terminal (Claude-Sessions)
```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project /Users/ingo/DocsMacMini/hobbies/programming/xcode/DrawThingsStoryboard/DrawThingsStoryboard.xcodeproj \
  -scheme DrawThingsStoryboard \
  -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"
```

## GitHub Issues abrufen (gh CLI — falls GitHub MCP-Tools deaktiviert)
```bash
gh issue list --repo SuperEugen/DrawThingsStoryboard --state open
gh issue view <NUMBER> --repo SuperEugen/DrawThingsStoryboard
```

## Known Swift Patterns & Pitfalls
- Type-checker timeout → split body into private structs with @Binding
- `AppConfig` must be `Equatable` for `.onChange(of:)` to work
- Job completion must always call `onJobCompleted` even on error, otherwise jobs hang
- Fresh ImageGenerationViewModel per job in QueueRunner (no accumulated state)
- Synchronous `isBusy` flag in QueueRunner prevents race condition re-entry
- `import Combine` required for `Timer.publish` (not included in SwiftUI alone)
- `DrawThingsConfiguration.sampler` is `SamplerType` enum, not String → use `samplerType(from:)` mapper
- `styleName` in GenerationJob should be the short style name, not the description/prompt

## Mermaid ERD Pitfalls
- `STYLE` is a reserved word in Mermaid → use `STYLEENTRY` as entity name
- Entity names must not contain underscores → use `GENERATEDIMAGE` not `GENERATED_IMAGE`
- Only `string` and `int` are reliable types → avoid `bool`, `float`, `double`
