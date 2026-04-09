# DrawThingsStoryboard — Feature Status (April 2026)

**Current version: v0.6**

## Implemented ✅

### Navigation & Layout
- 3-pane NavigationSplitView with 6 sections
- Sidebar: Models, Styles, Assets, Storyboards, Production Queue, Settings
- Section switch resets selections
- Queue status indicator in toolbar (spinner + job count + estimated finish time)
- Connection status indicator in toolbar (gRPC green/red dot)

### Models
- ModelEntry: name, model filename, steps, guidanceScale, sampler, isImg2ImgCapable
- Default generation times (small/large) per model
- Add / delete models
- Two default models: F2K KV (6 steps, CFG 1, img2img) and ZIB (35 steps, CFG 4)
- Sampler text field + Img2Img toggle in editor
- Sampler mapped to SamplerType enum for gRPC (all 20 types supported)

### Styles
- StyleEntry with name + style prompt
- Model picker in Styles header (independent per-section model selection)
- StyleTile shows generated example image from disk
- "E" badge for example status (green = generated, gray = pending)
- Generate Example → queued in Production Queue with modelID
- Combined prompt: style.style + config.stylePrompt

### Assets
- Character and location list with type/subType
- Grid view with Characters and Locations sections
- Model picker + Style picker in Assets header
- Variant thumbnails (4 slots, 2×2 grid)
- Generate Variants button per individual asset in detail view
- "Generate all Variants" batch button in Assets Browser
- "Generate all Large Images" batch button in Assets Browser
- Approve / disapprove variants
- Large image generation from approved variant (with seed)
- SubType picker (male/female, interior/exterior)
- Add new character or location via + menu
- Delete asset

### Storyboard
- Act → Sequence → Scene → Panel hierarchy
- Collapsible tree in browser with move up/down
- Model picker + Style picker in Storyboard header (bound to StoryboardEntry)
- Panel detail: name, description, camera movement, dialogue, duration
- S/L status indicators for small/large image
- Referenced assets (ref1ID–ref4ID) with location-first constraint
- Location image → canvas/init image, Character images → moodboard hints
- Generate Small/Large Image buttons in Panel detail
- Import Fountain screenplay files (.fountain) → Act/Sequence/Scene structure
- PDF export per act/sequence/scene (2×3 grid, A4)
- Multiple storyboards support with picker

### Production Queue
- VSplitView: queue on top, done list on bottom
- Jobs carry their own modelID (resolved from context when created)
- Model name shown in job rows (blue) alongside style name
- Step-level progress bar (e.g. step 47/140 for 4 variants × 35 steps)
- Variant progress header ("Generating 2/4…")
- Model-aware time estimation (filters production log by modelID + size)
- Estimated finish time in queue header + toolbar
- Stop button removes all waiting jobs
- Pushover notification toggle (bell icon, disabled when not configured)
- Image previews during generation

### Notifications (Pushover)
- PushoverService: fire-and-forget HTTP POST to pushover.net
- Credentials (API Token + User Key) in Settings
- Toggle in Production Queue header (persisted via @AppStorage)
- Per-job notification with duration, image count, remaining jobs
- Queue-complete notification with final summary

### Settings
- Draw Things: server address, port, shared secret
- Image sizes: small (W/H) + large (W/H)
- Style preview prompt
- Character turn-around prompt (prepended to character descriptions)
- Default panel duration
- Pushover: API Token + User Key (SecureField)
- Auto-save on change

### Storage (~/Pictures/DrawThings-Storyboard/)
- 6 JSON files: config, models, styles, storyboards, assets, production-log
- All images as <UUID>.png flat in root folder
- First-launch setup: demo data (4 characters, 4 locations, 3 styles, 2 models, 1 storyboard)
- StorageService, StorageSetupService, StorageLoadService

### Generation Pipeline
- Jobs carry modelID → QueueRunner resolves model from job (not global state)
- Sampler passed through entire pipeline: ModelEntry → VM → GenerationRequest → gRPC config
- Fresh ImageGenerationViewModel per job (no accumulated state)
- Synchronous isBusy flag prevents duplicate job generation
- Multi-variant support with fresh random seeds per variant
- Moodboard images for consistent character appearance in panels
- Production log entries with ISO8601 timestamps
