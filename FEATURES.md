# DrawThingsStoryboard — Feature Status (April 2026)

**Current version: v0.2.0**

## Implemented ✅

### Navigation & Layout
- 3-pane NavigationSplitView with 6 sections
- Sidebar: Storyboard, Assets, Styles, Models, Production Queue, Settings
- Section switch resets selections

### Storyboard
- Act → Sequence → Scene → Panel hierarchy
- Collapsible tree in browser
- Panel detail: name, description, camera movement, dialogue, duration
- S/L status indicators for small/large image
- Referenced assets (ref1ID–ref4ID) shown with type and name
- Each storyboard has a modelID and styleID

### Assets
- Character and location list with type/subType
- Grid view with Characters and Locations sections
- Variant thumbnails (4 slots, 2×2 grid)
- Approve / disapprove variants
- SubType picker (male/female for characters, interior/exterior for locations)
- Add new character or location via + menu
- Delete asset

### Styles
- StyleEntry with name + style prompt
- StyleTile shows generated example image from disk
- "E" badge for example status (green = generated, gray = pending)
- Generate Example → queued in Production Queue
- Combined prompt: style.style + config.stylePrompt
- After generation: image UUID written back to styles.json, shown in tile and detail

### Models
- ModelEntry: name, model (filename), steps, guidanceScale
- Default generation times (small/large) per model
- Add / delete models

### Production Queue
- VSplitView: queue on top, done list on bottom
- Model picker in title bar
- Job rows with type letter, size letter, item name, style name
- Done rows with completion time and duration
- Clear button for done list

### Generation
- Generate button with progress feedback
- Multi-variant support for asset jobs
- Images saved as UUID.png via StorageService
- Image UUIDs passed back via onJobCompleted → handleJobCompleted
- Style example: UUID written to StyleEntry.smallImageID, persisted to styles.json

### Settings
- Image sizes: small (W/H) + large (W/H)
- Style preview prompt (appended to style for example generation)
- Default panel duration
- Shared secret for Draw Things
- Auto-save on change via onChange

### Storage (~/Pictures/DrawThings-Storyboard/)
- 6 JSON files: config, models, styles, storyboards, assets, production-log
- All images as <UUID>.png flat in root folder
- First-launch setup creates demo data (4 characters, 4 locations, 3 styles, 1 model, 1 storyboard)
- StorageService with read/write JSON helpers
- StorageLoadService with individual save methods per JSON file

## Open / Next Steps 🔜
- Wire up asset generation (image UUIDs → AssetEntry variants)
- Wire up panel generation (image UUID → PanelEntry.smallImageID/largeImageID)
- Show variant images in Asset Browser (approved variant as actual image)
- Show panel images in Storyboard Browser
- Auto-process queue (generate all queued jobs in sequence)
- Proper error handling when Draw Things is not running
- Production log entries written after generation
