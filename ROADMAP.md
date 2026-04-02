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

## v0.3 — Complete Generation Wiring

Images are saved but not yet fully wired back into assets and panels.

- [ ] Asset variant generation: image UUIDs → AssetEntry.variant1–4.smallImageID
- [ ] Asset large image generation: UUID → AssetEntry.largeImageID
- [ ] Panel generation: UUID → PanelEntry.smallImageID / largeImageID
- [ ] Show actual variant images in Asset Browser tiles
- [ ] Show panel images in Storyboard Browser
- [ ] Production log entries written after each generation

## v0.4 — Production Workflow

The current "Generate (Test)" button is a proof of concept. The real workflow needs proper queue processing.

- [ ] Auto-process queue (generate all queued jobs in sequence)
- [ ] Retry failed jobs
- [ ] Job priority / reordering
- [ ] Proper error handling when Draw Things is not running
- [ ] gRPC address and port configurable in Settings

## v0.5 — More Draw Things Control

To get consistent images over several panels it is crucial to use the moodboard feature.

- [ ] Generate large image uses the same seed used for generation of variant or small image
- [ ] Generate panel uses reference images attached to the job

## v0.6 — Prompt Refinement

Better control of the prompts used to generate each image. A modular system.

- [ ] Prompt preview before queuing
- [ ] Prompt history per item
- [ ] Modular prompt assembly with reusable fragments

## v0.7 — Storyboard Export

The goal of the app. Something to hand out.

- [ ] Export storyboard as PDF (panels in sequence with scene descriptions)
- [ ] Export individual panels as PNG/JPEG
- [ ] Export asset sheet (all approved variants per character/location)

## v0.8 — Import Fountain Files

Connect to other apps in the whole production workflow.

- [ ] Import fountain file format used by screenwriting software like Beat to import acts, sequences and scenes
- [ ] Use fountain import to create character and location assets

## v0.9 — Dialog and Actions

Essential for a complete storyboard.

- [ ] Panel fields for dialogue, action instruction, camera movement already exist in data model
- [ ] UI polish for these fields in the Storyboard detail view

## v1.0 — Clean Up

The user interface and the code must be checked for a proper v1.

- [ ] Complete UI consistency check
- [ ] Create missing visuals
- [ ] Update documentation
- [ ] Code review and refactor where necessary

## Future Ideas

- **Draw Things on iPhone** — connect to Draw Things iOS over local network
- **Prompt templates** — reusable prompt building blocks beyond style suffixes
- **Export character turn-around sheets** — special prompts create turn-around sheets
- **Export characters as parted image** — separate elements for 2D character animation
- **Export vectorized assets** — usable in 2D animation software like Moho
- **Export Pitch Book** — export a pitch book to present the story
- **Export Video** — create a video from the storyboard
- **Support LoRAs** — add LoRA support in image generation
