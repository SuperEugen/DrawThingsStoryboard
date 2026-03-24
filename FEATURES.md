# DrawThingsStoryboard — Feature-Stand (März 2026)

## Implementiert ✅

### Navigation & Layout
- 3-Pane NavigationSplitView mit 7 Sections
- Sidebar mit korrekter Reihenfolge
- Section-Wechsel resettet Selection

### Projects (Briefing)
- Studio → Customer → Episode Hierarchie
- Preferred Look Picker (own/inherited, mit visueller Anzeige)
- Rules-Felder auf allen Ebenen
- Cast & Locations pro Episode

### Assets
- CastingItem Browser mit Grid-Ansicht (Library rechts, Editor links)
- Variant-Thumbnails (4 Slots, 2×2 Grid)
- Approve/Disapprove Variants
- isGenerated / isApproved Flags
- Add to Library auf Studio/Customer/Episode-Level
- Accept Changes nur bei tatsächlichen Änderungen (dirty tracking via Equatable)

### Looks
- GenerationTemplate mit Name + Description (Style-Prompt)
- LookTile zeigt generiertes Example-Bild (aus StorageService) statt Thumbnail
- "E"-Badge für Example-Status
- Generate Example → queued in Production Queue
- Combined Prompt: look.description + lookPromptCharacter/Location aus Config

### Storyboard
- Akt → Sequenz → Szene → Panel Hierarchie
- Collapsible Tree in Browser
- Panel Detail: Name, Description, S/L Status
- Attached Assets (max 4: 1 Location + 3 Characters)
- Generate Small/Large Panel → Queue
- Panel Job: look.description + lookPromptPanel + panel.description
- lookName korrekt aus resolvedLookName (reactive via @Binding)

### Model Config
- DTModelConfig: name, model (filename), steps, guidanceScale
- Mindestens 1 Config garantiert
- 2 Defaults: SDXL Standard, Flux Schnell

### Production Queue
- VSplitView: oben Queue, unten Done
- Model Picker in Titelzeile (aus DTModelConfig)
- ProductionJobRow: Job-Type Letter, Size Letter, Look+Item Thumbnails
  - generateExample: kein doppeltes Look-Thumbnail mehr
- DoneJobRow: Abschlusszeit + Dauer (startedAt → completedAt)
- Clear-Button für Done-Liste

### Generation (Test-Panel in Production Queue Detail)
- Generate-Button mit Stage-Feedback
- Multi-Variant für generateAsset-Jobs (alle variantCount Varianten)
- Variant-Anzeige als 2×2 Grid mit "V1/V2/..."-Badge
- Fortschrittsanzeige "Generating 2/4…"
- Nach Erfolg: Job → Done-Liste mit startedAt/completedAt
- Bilder-Speicherung via StorageService nach Generierung
- Saved-Pfad-Anzeige (grün) pro Variant

### Panel-Generierung (Assets im Moodboard)
- attachedAssets werden aus StorageService geladen (loadFirstAvailableVariant)
- Asset 1–3 → moodboardImages (shuffle ControlNet hints)
- Asset 4 → initImage (Canvas / img2img)

### Configuration
- Image Sizes: Small (W/H) + Large (W/H) via AppStorage
- Look Example Prompts: Character, Location, Panel via AppStorage
- Shared Secret Feld

### Storage (~/Pictures/DrawThings-Storyboard/)
- library/assets/<assetID>_v<n>.png — Variant-Bilder
- library/examples/<lookName>.png — Look-Examples
- <EpisodeName>/panels/<panelID>.png — Panel-Bilder

## Offen / Nächste Schritte 🔜
- Variant-Bilder in Asset-Browser anzeigen (approved variant als Thumbnail)
- Panel-Bilder im Storyboard-Browser anzeigen
- gRPC-Port und Adresse in Configuration konfigurierbar machen
- DTModelConfig persistent speichern (aktuell in-memory)
- MockData durch echte Persistenz ersetzen (SwiftData oder JSON)
- Proper error handling wenn Draw Things nicht läuft
- Prompt-Zusammensetzung für Asset-Jobs (item.description + item.prompt + look)
