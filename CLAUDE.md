# Chromafield

## Overview
Chromafield is a universal iOS/iPadOS generative art instrument built in Swift/SwiftUI + Metal. Users place field nodes (attractors, repellers, vortices, turbulence emitters) on a canvas with Apple Pencil or finger; thousands of particles respond in real-time to the combined force field. Free App Store release — no monetization, no accounts, no network. Portfolio piece.

## Tech Stack
- Swift: 5.10+
- SwiftUI: iOS 17+ (overlay UI only — NOT the canvas)
- Metal / MetalKit: iOS 17+ (MTKView, compute + render pipelines)
- AVFoundation: iOS 17+ (AVAssetWriter for MP4 export)
- UIKit: iOS 17+ (UIGestureRecognizer, UIViewRepresentable)
- Accelerate: iOS 17+ (CPU simulation fallback only)
- XCTest: bundled (headless simulation correctness tests)
- No SPM dependencies — all first-party

## Development Conventions
- Swift strict concurrency — no `@unchecked Sendable` without a comment explaining why
- PascalCase for types and files; camelCase for properties and functions
- Metal struct sizes must be multiples of 32 bytes — assert with `MemoryLayout<T>.size` in tests
- All gesture handling at the UIKit layer (UIGestureRecognizer on UIView) — never SwiftUI gestures on the canvas
- Conventional commits: feat:, fix:, perf:, refactor:, test:
- Write XCTest unit tests for every non-trivial data transform before committing

## Current Phase
**v1.0 Feature Complete** — All 3 phases implemented (Metal Engine, Interactive Canvas, Export + Polish).
See IMPLEMENTATION-ROADMAP.md for full architecture and phase details.

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Color system | 8 curated palettes (no free picker) | Curated palettes produce better outputs; free picker with 100K particles produces mud |
| Particle behaviors (v1) | 4: Flocking, Diffusion, Crystallization, Orbital | Enough variety without overwhelming onboarding |
| Field node visibility in exports | Hidden — nodes never rendered in export output | Nodes are editorial scaffolding; art is particles only |
| Export resolution | PNG: 2× screen on all devices; Video: 1× iPhone / 2× iPad | 4× risks OOM on iPhone; safe default confirmed |
| Canvas simulation resolution | Screen resolution always; export renders to offscreen texture | Interactivity requires screen-res simulation |
| Video export strategy | Non-realtime: pause sim, render N frames offline to AVAssetWriter | Avoids racing live simulation, prevents memory spikes |
| Gesture ownership | UIKit layer only — UIGestureRecognizer on underlying UIView | SwiftUI and MTKView fight over touch; UIKit wins |
| Persistence | JSON in Documents/configs/ | Field configs are < 5KB; JSON is debuggable; SQLite is overkill |
| Deployment target | iOS 17.0 | Metal 3 + SwiftUI + UIKit interop all stable at 17 |
| GIF export | Deferred to v2 | Palette quantization rabbit hole; MP4 covers sharing use case |

## Do NOT
- Do not use SwiftUI gestures on the canvas — all touch/Pencil input goes through UIGestureRecognizer on the UIView layer
- Do not attempt O(n²) neighbor scan for Flocking — use spatial grid hash + two-pass compute
- Do not record live simulation frames for video export — use the offline OffscreenRenderer path
- Do not request network entitlements — this app is fully offline, no exceptions
- Do not add v2 features (audio, time-varying fields, GIF export, 4× resolution) during the v1 build
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md
