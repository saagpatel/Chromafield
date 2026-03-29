# Chromafield

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](#)

> Up to 200,000 particles responding to your touch in real time — generative art as an instrument.

A GPU-accelerated particle field canvas for iPhone and iPad. Place field nodes with your finger or Apple Pencil, choose a particle behavior, and watch up to 200,000 particles respond in real time. Export the result as a PNG or MP4 video directly to your photo library.

## Features

- **Metal compute pipeline** — all particle physics (force evaluation, velocity integration) runs on the GPU
- **Four particle behaviors** — Flock, Diffuse, Crystal, Orbit — each producing distinct emergent patterns
- **Field nodes** — tap or draw to place attractor/repulsor nodes; long-press for a radial type menu
- **Apple Pencil support** — force, azimuth, and altitude mapped to field node parameters
- **Adaptive quality** — particle budget scales from 20,000 (A15) to 200,000 (M4) based on chip tier
- **Export** — still PNG via `PHPhotoLibrary`; MP4 video via `AVAssetWriter` through an offscreen Metal pass

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
