# Chromafield

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue?logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)
[![Metal](https://img.shields.io/badge/GPU-Metal-silver?logo=apple)](https://developer.apple.com/metal/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A GPU-accelerated particle field canvas for iPhone and iPad. Place field nodes with your finger or Apple Pencil, choose a particle behavior, and watch up to 200,000 particles respond in real time. Export the result as a PNG or MP4 video directly to your photo library.

---

## Screenshot

![Chromafield screenshot placeholder](docs/screenshot.png)

---

## Features

- **Metal compute pipeline** — particle physics (force evaluation, velocity integration) runs entirely on the GPU via `ParticleCompute.metal`
- **Four particle behaviors** — Flock, Diffuse, Crystal, Orbit — each producing a visually distinct emergent pattern
- **Field nodes** — tap or draw to place attractor/repulsor nodes; a radial menu appears on long-press to set node type
- **Apple Pencil support** — force, azimuth, and altitude values are mapped to field node parameters
- **Eight color palettes** — selectable via a horizontal palette strip
- **Preset gallery** — six bundled presets plus any configurations you save
- **Export** — still PNG via `PHPhotoLibrary`; MP4 video via `AVAssetWriter` rendered through an offscreen Metal pass
- **Adaptive quality** — particle budget scales automatically from 20,000 (A15) to 200,000 (M4) based on the detected chip tier

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6.0 (strict concurrency) |
| UI | SwiftUI + UIKit (UIViewRepresentable for the Metal canvas) |
| GPU | Metal — compute + render pipelines, triple-buffered |
| Export | `AVAssetWriter`, `PHPhotoLibrary` |
| Persistence | JSON encoded `FieldConfig` written to `Documents/configs/` |
| Project file | XcodeGen (`project.yml`) |

---

## Prerequisites

- Xcode 16 or later
- iOS 17.0+ deployment target (iPhone or iPad)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — to regenerate the `.xcodeproj` from `project.yml`

```bash
brew install xcodegen
```

---

## Getting Started

```bash
# 1. Clone
git clone https://github.com/saagpatel/Chromafield.git
cd Chromafield

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open Chromafield.xcodeproj
```

Select a simulator or connected device and press **Run** (⌘R).

> The Metal compute pipeline requires a physical device or an Apple Silicon Mac running a simulator for full performance. Particle budgets are capped on older simulators.

---

## Project Structure

```
Chromafield/
├── Chromafield/
│   ├── App/            # @main entry point, root ContentView
│   ├── Metal/          # MetalEngine, ParticleBuffer, OffscreenRenderer, .metal shaders
│   ├── Simulation/     # FieldManager, FieldNodeModel, ParticleBehavior, SimulationConfig
│   ├── Input/          # GestureCoordinator, PencilInputHandler, InputMapper
│   ├── UI/             # SwiftUI overlay views (RadialNodeMenu, BehaviorPicker, PaletteSelector, …)
│   ├── Persistence/    # PersistenceManager, FieldConfig (Codable)
│   ├── Export/         # ImageExporter, VideoExporter
│   ├── Utilities/      # DeviceCapabilities, FrameBudgetMonitor, ColorPalette
│   └── Resources/      # 6 bundled preset JSON files, Assets.xcassets
└── ChromafieldTests/   # Unit tests (simulation correctness, persistence, input mapping)
```

---

## Running Tests

```bash
xcodebuild test \
  -scheme Chromafield \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## License

MIT — see [LICENSE](LICENSE).
