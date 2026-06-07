# Chromafield

Universal iOS/iPadOS generative art instrument — Swift/SwiftUI + Metal. Users place field nodes on a canvas; thousands of particles respond in real-time. Free App Store release, fully offline, no accounts. Portfolio piece.

## Stack
- Swift 6.0 (strict concurrency)
- SwiftUI iOS 17+ (overlay UI only — NOT the canvas)
- Metal / MetalKit iOS 17+ (MTKView, compute + render pipelines)
- AVFoundation iOS 17+ (AVAssetWriter for MP4 export)
- UIKit iOS 17+ (UIGestureRecognizer, UIViewRepresentable)
- XCTest bundled (simulation, persistence, input, export, and utility unit tests)
- No SPM dependencies — all first-party

## Build / Test / Run

Build and run on a physical device for full GPU performance. See IMPLEMENTATION-ROADMAP.md for architecture and phase details.

## Gotchas

**Canvas input:** All touch and Apple Pencil input goes through UIGestureRecognizer on the UIView layer. SwiftUI and MTKView fight over touch; UIKit wins. Never route canvas gestures through SwiftUI.

**Flocking performance:** Use spatial grid hash + two-pass compute. O(n²) neighbor scan is too slow at particle counts this app targets.

**Video export:** Use the offline OffscreenRenderer path — pause the sim, render N frames to AVAssetWriter. Recording live simulation frames races the sim and causes memory spikes.

**Network entitlements:** This app is fully offline; network entitlements must not be added.

**Scope gate:** GIF export, audio, time-varying fields, and 4× resolution are v2 scope — keep them out of v1 builds. Stick to IMPLEMENTATION-ROADMAP.md for the active phase boundary.

## Conventions
- Swift strict concurrency — `@unchecked Sendable` requires an inline comment explaining why
- Metal struct sizes must be multiples of 32 bytes — assert with `MemoryLayout<T>.size` in tests
- XCTest unit tests for every non-trivial data transform before committing
- Conventional commits: feat:, fix:, perf:, refactor:, test:
- PascalCase for types/files; camelCase for properties/functions

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Color system | 8 curated palettes (no free picker) | Free picker with 100K particles produces mud |
| Particle behaviors (v1) | 4: Flocking, Diffusion, Crystallization, Orbital | Enough variety without overwhelming onboarding |
| Field node visibility in exports | Hidden — nodes never rendered in export output | Nodes are editorial scaffolding; art is particles only |
| Export resolution | PNG: 2× on M-series + A17/A18; 1× on A15/A16/unknown; Video: 2× on M-series iPad, 1× otherwise | 4× risks OOM on iPhone; safe default confirmed |
| Canvas simulation resolution | Screen resolution always; export renders to offscreen texture | Interactivity requires screen-res simulation |
| Video export strategy | Non-realtime: pause sim, render N frames offline to AVAssetWriter | Avoids racing live simulation, prevents memory spikes |
| Gesture ownership | UIKit layer only — UIGestureRecognizer on underlying UIView | SwiftUI and MTKView fight over touch; UIKit wins |
| Persistence | JSON in Documents/configs/ | Field configs are < 5KB; JSON is debuggable; SQLite is overkill |
| Deployment target | iOS 17.0 | Metal 3 + SwiftUI + UIKit interop all stable at 17 |
| GIF export | Deferred to v2 | Palette quantization rabbit hole; MP4 covers sharing use case |

<!-- portfolio-context:start -->
# Portfolio Context

## What This Project Is

Chromafield is a universal iOS/iPadOS generative art instrument built in Swift/SwiftUI + Metal. Users place field nodes (attractors, repellers, vortices, turbulence emitters) on a canvas with Apple Pencil or finger; thousands of particles respond in real-time to the combined force field. Free App Store release — no monetization, no accounts, no network. Portfolio piece.

## Current State

**v1.0 Feature Complete** — All 3 phases implemented (Metal Engine, Interactive Canvas, Export + Polish).
See IMPLEMENTATION-ROADMAP.md for full architecture and phase details.

## Stack

- Swift: 6.0 (strict concurrency)
- SwiftUI: iOS 17+ (overlay UI only — NOT the canvas)
- Metal / MetalKit: iOS 17+ (MTKView, compute + render pipelines)
- AVFoundation: iOS 17+ (AVAssetWriter for MP4 export)
- UIKit: iOS 17+ (UIGestureRecognizer, UIViewRepresentable)
- XCTest: bundled (simulation, persistence, input, export, and utility unit tests)
- No SPM dependencies — all first-party

## How To Run

Build and run on a physical device for full GPU performance. Tap the canvas to place field nodes and use the behavior strip to switch particle modes.

## Known Risks

- Do not use SwiftUI gestures on the canvas — all touch/Pencil input goes through UIGestureRecognizer on the UIView layer
- Do not attempt O(n²) neighbor scan for Flocking — use spatial grid hash + two-pass compute
- Do not record live simulation frames for video export — use the offline OffscreenRenderer path
- Do not request network entitlements — this app is fully offline, no exceptions
- Do not add v2 features (audio, time-varying fields, GIF export, 4× resolution) during the v1 build
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md

## Next Recommended Move

Use this context plus the README and supporting docs to resume the next active task, then promote the repo beyond minimum-viable by capturing a dedicated handoff, roadmap, or discovery artifact.

<!-- portfolio-context:end -->

<!-- secondbrain-breadcrumb -->
## SecondBrain knowledge vault

Prior lessons, decisions, and context for this project live in SecondBrain at `wiki/maps/projects/chromafield.md`. The whole vault is searchable via the `engraph` MCP — query it for this project + its stack before non-trivial work.
