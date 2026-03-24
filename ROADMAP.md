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

## v0.5 - More Draw Things control

To get consistant images over several panels it is crucial to use the moodboard feature.

- [ ] Generate large image uses the same seed used for generation of variant or small image
- [ ] Generate panel use reference images attached to the job

## v0.6 — Prompt refinement

Better control of the prompts used to generate each image. A modular system.

- [ ] Prompt assembly for Asset jobs: `item.description` + `item.prompt` + look suffix
- [ ] Prompt preview before queuing
- [ ] Prompt history per item

## v0.7 — Storyboard export

The goal of the app. Something to hand out.

- [ ] Export storyboard as PDF (panels in sequence with scene descriptions)
- [ ] Export individual panels as PNG/JPEG
- [ ] Export asset sheet (all approved variants per character/location)

## 0.8 - Import fountain files

Connect to other apps in the whole production workflow.

- [ ] Import fountain file format used by screenwriting software like Beat to import acts, sequences and scenes
- [ ] Use fountain import to create character and location assets

## 0.9 - Dialog and actions

Essential for a complete storyboard.

- [ ] New fields for each panel for character dialog, action instruction and camera movement and framing are included

## 1.0 - Clean up

The user interface and the code must be checked to have a prober v1.

- [ ]  The complete UI must be checked for consistancy and ease of use
- [ ]  Create missing visuals
- [ ]  Update documentation
- [ ]  Check the code and refactor where necessary

## Future ideas

- **Draw Things on iPhone** — connect to Draw Things iOS over local network
- **Prompt templates** — reusable prompt building blocks beyond look suffixes
- **Export character turn-around sheets** - special prompts create a turn-around sheet for a character
- **Export characters as parted image** - special prompts create characters with separate elements for 2d character animation
- **Export vectorized assets** - usable in 2d animation software like Moho
- **Export Pitch-Book** - export a pitch book to present the story to someone
- **Export Video** - create a video out of the storyboard
- **Support LoRAs** - add LoRA support in the generation of images
