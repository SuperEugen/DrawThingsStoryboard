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
- [x] Fallback estimation: 60s small, 180s large when no log data
- [x] "Generate Large Image" button per asset in detail view (with seed from approved variant)
- [x] Large image preview with full-size sheet viewer (800×500)
- [x] Import Fountain screenplay files (.fountain) → Act/Sequence/Scene structure
- [x] FountainParser strips Beat metadata blocks
- [x] Style selector picker in Storyboard Browser header
- [x] Generate Small/Large Image buttons in Panel detail view (enabled when description exists)
- [x] +/Delete buttons for Acts, Sequences, Scenes, and Panels in storyboard tree
- [x] Sidebar reordered: Assets, Styles, Models, Storyboard, Production Queue, Settings
- [x] Proper default descriptions for location assets in demo data
- [x] Race condition fix: synchronous isBusy flag prevents duplicate job generation
- [x] Fresh ImageGenerationViewModel per job (no accumulated state between jobs)

## v0.5 — More Draw Things Control

To get consistent images over several panels it is crucial to use the moodboard feature.

- [x] Generate panel uses reference images (approved asset variants) attached to the job
- [x] Moodboard images sent via gRPC for consistent character appearance
- [x] Export storyboard as PDF (panels in sequence with scene descriptions)

## v0.6 - Improved Character Assets Handling

Character turn-around sheets improve panel creation and asset export.

- [ ] UI Updates
- [ ] Create assets for all styles.
- [ ] Add prompt fragments to character assets to create a proper turn-around sheet.
- [ ] Export one or all character turn-around sheets.
- [ ] Add prompt fragment to character assets to separate body parts for 2d animation use.
- [ ] Export one or all character parts sheets.

## v0.7 — Fountain Import Phase 2

Deeper integration with Fountain screenplay files.

- [ ] Import dialogue lines from Fountain files into panel dialogue fields
- [ ] Auto-create character assets from Fountain character names
- [ ] Map Fountain scene headings to location assets
- [ ] Panel fields for dialogue, action instruction, camera movement already exist in data model
- [ ] UI polish for these fields in the Storyboard detail view and export.

## v0.8 — Customization for Storyboard PDFs

Custom option for the exported storyboard.

- [ ] Columns, rows, title etc.

## v0.9 — Clean Up

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
