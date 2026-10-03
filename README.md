# Chromafield

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](#)

> Up to 200,000 particles responding to your touch in real time — generative art as an instrument.

A GPU-accelerated particle field canvas for iPhone and iPad. Place field nodes with your finger or Apple Pencil, choose a particle behavior, and watch up to 200,000 particles respond in real time. Export the result as a PNG or MP4 video directly to your photo library.

## Features

- **Metal compute pipeline** — all particle physics (force evaluation, velocity integration) runs on the GPU
- **Four particle behaviors** — Flock, Diffuse, Crystal, Orbit — each producing distinct emergent patterns
- **Field nodes** — tap to place attractors, draw with Apple Pencil to place and move an attractor; long-press for a radial type menu
- **Apple Pencil support** — force, azimuth, and altitude mapped to field node parameters
- **Adaptive quality** — particle budget scales from 20,000 (A15) to 200,000 (M4) based on chip tier
- **Export** — still PNG via `PHPhotoLibrary`; MP4 video via `AVAssetWriter` through an offscreen Metal pass
- **Ready-to-edit launch canvas** — starts from the bundled Nebula composition instead of an empty or saturated field

## Quick Start

### Prerequisites
- Xcode 16+
- iOS 17.0+ (iPhone or iPad)
- XcodeGen (`brew install xcodegen`)

### Installation
```bash
git clone https://github.com/saagpatel/Chromafield.git
cd Chromafield
xcodegen generate
open Chromafield.xcodeproj
```

### Verification

Run from the repository root. Build and test require macOS with the full Xcode
16+ developer directory selected; Command Line Tools alone cannot run the iOS
Simulator lane. Tests also require an installed, available iPhone simulator
runtime compatible with the iOS 17 deployment target. `make test` selects the
first available iPhone simulator and can boot it and create test app data.

```sh
make build   # regenerate with XcodeGen, then build Debug for iOS Simulator
make test    # regenerate, then run the ChromafieldTests suite
```

For a focused model test, generate the project and supply an available iPhone
simulator's UDID in place of `AVAILABLE_IPHONE_UDID`:

```sh
xcodegen generate
xcodebuild test -project Chromafield.xcodeproj -scheme Chromafield \
  -destination 'platform=iOS Simulator,id=AVAILABLE_IPHONE_UDID' \
  -only-testing:ChromafieldTests/FieldNodeModelTests CODE_SIGNING_ALLOWED=NO
```

[CI](.github/workflows/ci.yml) also validates release resources and builds the
Release configuration. The resource-only lane needs macOS `plutil` and `jq` and
does not launch the app:

```sh
plutil -lint Chromafield/Resources/PrivacyInfo.xcprivacy
plutil -lint ExportOptions.plist
jq -s -e 'length == 6' Chromafield/Resources/Presets/*.json >/dev/null
```

There is no separate configured Swift lint or format command. For changed canvas,
input or export behavior, check the affected flow on a simulator and, where Metal
performance or Apple Pencil matters, an appropriate device. Browser checks do
not exercise this native app. Device runs and exports can write app/Photos data;
use disposable test data when those checks are in scope. Documentation-only
changes do not require launching the app. Simulator tests do not establish device
performance or Photos export acceptance; signing, archive and App Store export
are separate delivery operations.

### Usage
Build and run on a physical device for full GPU performance. Tap the canvas to place field nodes and use the behavior strip to switch particle modes.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6.0 (strict concurrency) |
| UI | SwiftUI + UIKit (UIViewRepresentable for Metal canvas) |
| GPU | Metal — compute + render pipelines, triple-buffered |
| Export | AVAssetWriter, PHPhotoLibrary |
| Persistence | JSON FieldConfig files in Documents/configs/ |
| Build | XcodeGen (project.yml) |

## License

MIT
