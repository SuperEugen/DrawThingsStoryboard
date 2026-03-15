# DrawThingsStoryboard

A native macOS SwiftUI app for creating AI-generated storyboards using the [Draw Things](https://drawthings.ai) HTTP API.

## Overview

DrawThingsStoryboard follows a film production metaphor to help you build visual stories:

| Phase | Description |
|-------|-------------|
| **Briefing** | General project configuration |
| **Casting** | Define characters and locations |
| **Writing** | Script and scene structure |
| **Production** | Generate and assemble panels |

Assets are organized in a portable **Library** hierarchy: Studio → Customer → Episode.

## Requirements

- macOS 14.0+
- [Draw Things](https://drawthings.ai) running locally with HTTP API enabled (default: `localhost:7888`)
- Xcode 15+

## Getting Started

```bash
git clone https://github.com/SuperEugen/DrawThingsStoryboard.git
cd DrawThingsStoryboard
open DrawThingsStoryboard.xcodeproj
```

Build and run in Xcode. Make sure Draw Things is running before using the Production phase.

## Project Structure

```
DrawThingsStoryboard/
├── App/                  # Entry point, navigation, routing
├── Features/
│   ├── ItemBrowser/      # Center + right pane views
│   ├── Library/          # Library hierarchy navigator
│   ├── ImageGeneration/  # Draw Things API integration
│   └── Settings/         # App settings
├── Models/               # Data models and mock data
└── Services/             # HTTP client and protocols
```

## Contributing

See [CONTRIBUTORS.md](CONTRIBUTORS.md).

## License

MIT
