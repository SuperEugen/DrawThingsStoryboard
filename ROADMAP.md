# DrawThingsStoryboard — Roadmap

This roadmap outlines the planned development direction. Items are grouped by theme, not by strict release order. Priorities may shift based on feedback and available time.

## v0.2 — Persistence

The biggest gap in the current version: all project data is lost when the app quits.

- [ ] Define JSON format for project data (see `ARCHITECTURE.md`)
- [ ] `Codable` conformance on all models
- [ ] Save/load project via JSON file(s)
- [ ] Auto-save on change
- [ ] Multiple projects / recent projects list
- [ ] Persistent `DTModelConfig` (currently in-memory only)

## v0.3 — Generated images in the UI

Images are already saved to disk, but not yet shown back in the app.

- [ ] Approved variant image as thumbnail in Asset Browser
- [ ] Panel images shown in Storyboard Browser tiles
- [ ] Look example image already works — extend pattern to assets and panels

## v0.4 — Production workflow

The current "Generate (Test)" button is a proof of concept. The real workflow needs proper queue processing.

- [ ] Auto-process queue (generate all queued jobs in sequence)
- [ ] Retry failed jobs
- [ ] Job priority / reordering
- [ ] Proper error handling when Draw Things is not running
- [ ] gRPC address and port configurable in Settings

## v0.5 — Prompt refinement

- [ ] Prompt assembly for Asset jobs: `item.description` + `item.prompt` + look suffix
- [ ] Negative prompt support per job type
- [ ] Prompt preview before queuing
- [ ] Prompt history per item

## v0.6 — Storyboard export

- [ ] Export storyboard as PDF (panels in sequence with scene descriptions)
- [ ] Export individual panels as PNG/JPEG
- [ ] Export asset sheet (all approved variants per character/location)

## Future ideas

- **iCloud sync** — share projects across devices via CloudKit
- **Draw Things on iPhone** — connect to Draw Things iOS over local network
- **Prompt templates** — reusable prompt building blocks beyond look suffixes
- **Scene descriptions** — auto-generate panel descriptions from scene text using Claude
- **Storyboard timeline view** — horizontal scrolling view across acts and sequences
- **Version history** — track changes to panels and prompts over time
