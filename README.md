# DrawThingsStoryboard

A native macOS app for AI-assisted storyboard production, powered by [Draw Things](https://drawthings.ai).

DrawThingsStoryboard organises your visual storytelling workflow around a film production metaphor — from casting characters and locations, through writing scenes, to generating panels with AI. It talks to Draw Things over gRPC, so you get full access to ControlNet hints, moodboard reference images, and every model Draw Things supports.

## Features

- **Projects** — Studio → Customer → Episode hierarchy with inherited Look preferences and production rules
- **Assets** — Character and location library with variant generation (up to 4 variants per item, approve/disapprove workflow)
- **Looks** — Visual style templates that assemble prompts from description + type-specific suffixes; generates example images
- **Storyboard** — Act → Sequence → Scene → Panel hierarchy; attach up to 4 assets per panel (3 moodboard + 1 canvas)
- **Model Config** — Named Draw Things model configurations (model filename, steps, guidance scale)
- **Production Queue** — Queued jobs with model picker, live generation progress, and done list with timing
- **Local storage** — All generated images saved to `~/Pictures/DrawThings-Storyboard/` with a structured layout

## Requirements

- macOS 14.0+
- Xcode 15+
- [Draw Things](https://drawthings.ai) with **gRPC API enabled** (Advanced → API Server → Protocol: gRPC)

## Getting Started

```bash
git clone https://github.com/SuperEugen/DrawThingsStoryboard.git
cd DrawThingsStoryboard
open DrawThingsStoryboard.xcodeproj
```

Build and run in Xcode (⌘R). Before generating images, make sure Draw Things is running with gRPC enabled.

### Draw Things configuration

In Draw Things, go to **Advanced → API Server** and set:

| Setting | Value |
|---------|-------|
| Server Online | enabled |
| Protocol | gRPC |
| Port | 7859 (default) |
| Transport Layer Security | enabled |

The app connects to `localhost:7859` with TLS by default. Port and address can be adjusted in the **Configuration** section of the app.

## How It Works

### Prompt assembly

Every generation job assembles its prompt from several pieces:

- **Asset variants** — `item.description` + `item.prompt`
- **Look examples** — `look.description` + look prompt suffix (Character / Location, configured in Settings)
- **Panels** — `look.description` + panel prompt suffix + `panel.description`

### Panel generation and reference images

When a panel job is generated, attached assets are loaded from the local library and passed to Draw Things as ControlNet shuffle hints (moodboard). Up to 3 assets go into the moodboard; a 4th asset is passed as the canvas image (img2img).

### Output structure

```
~/Pictures/DrawThings-Storyboard/
├── library/
│   ├── assets/          # <assetID>_v0.png, _v1.png, …
│   └── examples/        # <lookName>.png
└── <EpisodeName>/
    └── panels/          # <panelID>.png
```

## Project Structure

```
DrawThingsStoryboard/
├── App/                    # Entry point, sidebar, routing (ContentView)
├── Features/
│   ├── ItemBrowser/        # Queue, looks, configuration, casting views
│   ├── Library/            # Asset library browser
│   ├── ModelConfig/        # DTModelConfig browser and editor
│   ├── Storyboard/         # Act/Sequence/Scene/Panel views
│   ├── ImageGeneration/    # ViewModel and generation logic
│   └── Shared/             # UnifiedThumbnailView and helpers
├── Models/                 # Data models and mock data
└── Services/
    ├── DrawThingsClient/   # gRPC, HTTP, and mock clients
    └── Storage/            # StorageService (file system)
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [euphoriacyberware-ai/DT-gRPC-Swift-Client](https://github.com/euphoriacyberware-ai/DT-gRPC-Swift-Client) | Draw Things gRPC client (grpc-swift, swift-protobuf, flatbuffers) |

> [!NOTE]
> Add the package in Xcode via **File → Add Package Dependencies** using the URL above.

## Contributing

See [CONTRIBUTORS.md](CONTRIBUTORS.md).
