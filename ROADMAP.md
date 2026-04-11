# DrawThingsStoryboard — Roadmap

This roadmap outlines the planned development direction. Items are grouped by theme, not by strict release order. Priorities may shift based on feedback and available time.

## v0.2 — Flat JSON Storage & Simplified Data Model ✅

Completed: April 2026

- [x] Replace Studio/Customer/Episode hierarchy with flat 6-JSON storage
- [x] All images stored as UUID.png in single root folder
- [x] Codable structs matching JSON schema (DataModels.swift)
- [x] StorageSetupService creates demo data on first launch
- [x] StorageLoadService reads/writes all 6 JSON files
- [x] Rename Looks → Styles throughout
- [x] Remove Projects section
- [x] New sidebar: Storyboard, Assets, Styles, Models, Production Queue, Settings
- [x] Seed 0 = unassigned, app generates random seeds
- [x] Style example generation writes UUID back to styles.json
- [x] Generated style images shown in tiles and detail view

## v0.3 — Complete Generation Wiring ✅

Completed: April 2026

- [x] Asset variant generation: image UUIDs → AssetEntry.variant1–4.smallImageID
- [x] Asset large image generation: UUID → AssetEntry.largeImageID (uses seed from approved variant)
- [x] Panel generation: UUID → PanelEntry.smallImageID / largeImageID
- [x] Show actual variant images in Asset Browser tiles and detail view
- [x] Show panel images in Storyboard Browser (mini thumbnails in panel rows)
- [x] Production log entries written after each generation to production-log.json
- [x] "Generate all Variants" batch button in Assets Browser
- [x] "Generate all Large Images" batch button in Assets Browser
- [x] UnifiedThumbnailView supports real images via imageID parameter

## v0.4 — Production Workflow & Fountain Import ✅

Completed: April 2026

- [x] QueueRunnerService: auto-process queue (jobs start automatically, sequential processing)
- [x] Manual Generate button removed — queue is fully automatic
- [x] Stop button removes all waiting jobs (running job finishes)
- [x] Production log persistence — time estimation from last 3 jobs per size (small/large)
- [x] "Generate Large Image" button per asset in detail view (with seed from approved variant)
- [x] Large image preview with full-size sheet viewer (800×500)
- [x] Import Fountain screenplay files (.fountain) → Act/Sequence/Scene structure
- [x] Style selector picker in Storyboard Browser header
- [x] Generate Small/Large Image buttons in Panel detail view
- [x] +/Delete buttons for Acts, Sequences, Scenes, and Panels in storyboard tree
- [x] Fresh ImageGenerationViewModel per job (no accumulated state)

## v0.5 — Moodboard & PDF Export ✅

Completed: April 2026

- [x] Generate panel uses reference images (approved asset variants) attached to the job
- [x] Location image → canvas/init image for consistent backgrounds
- [x] Character images → moodboard/shuffle hints for consistent appearance
- [x] Export storyboard as PDF (panels in 2×3 grid, A4)
- [x] Character turn-around prompt prepended to character asset descriptions
- [x] Add prompt fragments to character assets to create proper turn-around sheets

## v0.6 — Multi-Model Support & Notifications ✅

Completed: April 2026

- [x] ModelEntry: sampler (text field) + isImg2ImgCapable (boolean)
- [x] Two default models: F2K KV (Flux, 6 steps) + ZIB (35 steps, CFG 4)
- [x] Model Selector in Assets, Styles, and Storyboard headers
- [x] Jobs carry their own modelID (set at creation time from active model picker)
- [x] QueueRunner resolves model from job.modelID (not global selectedModelID)
- [x] Sampler mapped to SamplerType enum for gRPC (all 20 Draw Things samplers)
- [x] Model-aware time estimation (filters production log by modelID + size)
- [x] Queue status indicator in app toolbar (spinner + job count + estimated finish)
- [x] Step-level progress bar (e.g. 47/140 for 4×35 steps)
- [x] Pushover notification integration (per-job + queue-complete messages)
- [x] Notification toggle in Production Queue header (persisted via @AppStorage)
- [x] Pushover credentials (token + user) in Settings as SecureField
- [x] Model name shown in queue job rows and detail view
- [x] Style name (not description) shown in job rows
- [x] Generate Variants button per individual asset in detail view
- [x] Sidebar reordered: Models, Styles, Assets, Storyboards, Production Queue, Settings
- [x] Removed global Model Selector from Production Queue (jobs carry own model)

## v0.7 — UX Improvements & Character Sheet Export ✅

Completed: April 2026

- [x] Action menus compacted: icon-only buttons with full-text tooltips (Styles, Assets, Storyboard views)
- [x] Dividers between model/style pickers and action buttons in Styles and Assets menus
- [x] Storyboard tree: inline Plus buttons removed — all add actions via Action Menu
- [x] Storyboard tree: delete buttons disabled (not hidden) when last element at level
- [x] Minimum structure enforced: 1 storyboard → 1 act → 1 sequence → 1 scene → 1 panel
- [x] Export Character Sheets as PDF (one full-page per character: large image + name caption)
- [x] Character sheet export scoped to current style and characters with large images

## v0.8 — Improved Import

Overall improved import and deeper integration with Fountain screenplay files.

- [ ] Import assets (without images)
- [ ] Import styles (without examples)
- [ ] Import dialogue lines from Fountain files into panel dialogue fields
- [ ] Auto-create character assets from Fountain character names
- [ ] Map Fountain scene headings to location assets
- [ ] UI polish for dialogue/action/camera fields in Storyboard detail and export

## v0.9 — Customization for Storyboard PDFs

Custom options for the exported storyboard.

- [ ] Configurable columns, rows, title etc.

## v1.0 — Clean Up

The user interface and the code must be checked for a proper v1.

- [ ] Proper error handling when Draw Things is not running
- [ ] Complete UI consistency check
- [ ] Create missing visuals
- [ ] Update documentation
- [ ] Code review and refactor where necessary

## Future Ideas

- **Draw Things on iPhone** — connect to Draw Things iOS over local network
- **Export vectorized assets** — usable in 2D animation software like Moho
- **Export Pitch Book** — export a pitch book to present the story
- **Export Video** — create a video from the storyboard
- **Support LoRAs** — add LoRA support in image generation
