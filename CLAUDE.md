# DrawThingsStoryboard — Claude Context

This file gives Claude Code the project context needed to work effectively.

## What this app does

DrawThingsStoryboard is a macOS SwiftUI app that talks to the [Draw Things](https://drawthings.ai)
HTTP API to generate images locally. Built step by step, starting from image generation
and growing towards storyboard / scene management features.

## Architecture rules

- **MVVM** strictly — every View has exactly one ViewModel, no logic in Views
- **Feature folders** under `Features/` — each feature is self-contained with its own `Views/` and `ViewModels/`
- **Services** are protocol-backed (`DrawThingsClientProtocol`) for testability
- **SwiftData** models live in `Models/` — one file per model, no monolithic schema files
- **No file over ~300 lines** — split into smaller focused files instead
- **`@MainActor`** on all ViewModels
- **Deployment target**: macOS 14.0
- **Swift version**: 5.10+

## Folder structure

```
DrawThingsStoryboard/
├── App/                    # Entry point, commands, routing
├── Features/
│   ├── ImageGeneration/    # Draw Things API image generation
│   │   ├── Views/
│   │   └── ViewModels/
│   └── Settings/
│       ├── Views/
│       └── ViewModels/
├── Services/
│   └── DrawThingsClient/   # Protocol + HTTP implementation + Mock
├── Models/                 # GenerationRequest, GenerationResponse, SwiftData models
└── Resources/              # Assets.xcassets
```

## Key design decisions vs DrawThingsStudio

- Feature-based folder structure instead of flat file list
- One SwiftData model per file instead of one huge schema
- Smaller, composable Views (target: no View file over 200 lines)
- Protocol-backed services for easy mocking in previews

## Draw Things HTTP API

Base URL: `http://localhost:7888` (configurable in Settings)
Key endpoint: `POST /sdapi/v1/txt2img`
Docs: https://github.com/drawthingsai/draw-things-community
