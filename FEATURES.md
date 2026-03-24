# DrawThingsStoryboard — Feature Status (March 2026)

**Current release: v0.1.0 (Pre-Release)**

## Implemented ✅

### Navigation & Layout
- 3-pane NavigationSplitView with 7 sections
- Sidebar with correct ordering
- Section switch resets selection

### Projects (Briefing)
- Studio → Customer → Episode hierarchy
- Preferred Look picker (own/inherited, with visual indicator)
- Rules fields at all hierarchy levels
- Cast & locations per episode

### Assets
- CastingItem browser with grid view (Library on right, editor on left)
- Variant thumbnails (4 slots, 2×2 grid)
- Approve / disapprove variants
- isGenerated / isApproved flags
- Add to Library at Studio / Customer / Episode level
- Accept Changes only on actual modifications (dirty tracking via Equatable)

### Looks
- GenerationTemplate with name + description (style prompt)
- LookTile shows generated example image (from StorageService) instead of thumbnail
- "E" badge for example status
- Generate Example → queued in Production Queue
- Combined prompt: look.description + lookPromptCharacter/Location from Config

### Storyboard
- Act → Sequence → Scene → Panel hierarchy
- Collapsible tree in browser
- Panel detail: name, description, S/L status
- Attached assets (max 4: 1 location + 3 characters)
- Generate Small / Large Panel → Queue
- Panel job: look.description + lookPromptPanel + panel.description
- lookName correctly resolved from resolvedLookName (reactive via @Binding)

### Model Config
- DTModelConfig: name, model (filename), steps, guidanceScale
- At least 1 config guaranteed
- 2 defaults: SDXL Standard, Flux Schnell

### Production Queue
- VSplitView: queue on top, done list on bottom
- Model picker in title bar (from DTModelConfig)
- ProductionJobRow: job-type letter, size letter, Look + item thumbnails
  - generateExample: no duplicate Look thumbnail
- DoneJobRow: completion time + duration (startedAt → completedAt)
- Clear button for done list

### Generation (Test Panel in Production Queue Detail)
- Generate button with stage feedback
- Multi-variant for generateAsset jobs (all variantCount variants)
- Variant display as 2×2 grid with "V1/V2/..." badge
- Progress indicator "Generating 2/4…"
- On success: job → done list with startedAt/completedAt
- Image saving via StorageService after generation
- Saved path display (green) per variant

### Panel Generation (Assets in Moodboard)
- attachedAssets loaded from StorageService (loadFirstAvailableVariant)
- Assets 1–3 → moodboardImages (shuffle ControlNet hints)
- Asset 4 → initImage (canvas / img2img)

### Configuration
- Image sizes: Small (W/H) + Large (W/H) via AppStorage
- Look example prompts: Character, Location, Panel via AppStorage
- Shared secret field

### Storage (~/Pictures/DrawThings-Storyboard/)
- library/assets/\<assetID\>_v\<n\>.png — variant images
- library/examples/\<lookName\>.png — look examples
- \<EpisodeName\>/panels/\<panelID\>.png — panel images

## Open / Next Steps 🔜
- Show variant images in Asset Browser (approved variant as thumbnail)
- Show panel images in Storyboard Browser
- Make gRPC port and address configurable in Configuration
- Persist DTModelConfig (currently in-memory only)
- Replace mock data with real persistence (SwiftData or JSON)
- Proper error handling when Draw Things is not running
- Prompt assembly for Asset jobs (item.description + item.prompt + look)
