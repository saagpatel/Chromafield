# Chromafield — Implementation Roadmap

## Architecture

### System Overview

```
[Apple Pencil / Touch Input]
         │
         ▼
[GestureCoordinator (UIKit layer)]
         │  field node add/move/remove events
         ▼
[FieldManager] ──── [FieldNode[]] ─────────────────────┐
         │                                              │
         │  uploads field data to GPU buffer            │
         ▼                                              ▼
[MetalEngine]                               [SwiftUI Overlay]
  ├── ParticleCompute.metal                   ├── RadialNodeMenu
  │     (force eval + velocity integration)   ├── BehaviorPicker
  ├── ParticleRender.metal                    ├── PaletteSelector
  │     (point sprites + trail accumulation)  ├── PresetGallery
  ├── MTKView (live canvas)                   └── ExportControls
  └── OffscreenRenderer
         │  (export-only, non-realtime)
         ▼
[ExportPipeline]
  ├── ImageExporter  → PHPhotoLibrary + UIActivityViewController
  └── VideoExporter  → AVAssetWriter → Camera Roll
         │
[PersistenceManager]
  └── FieldConfig JSON → Documents/configs/{uuid}.json
```

### File Structure

```
Chromafield/
├── Chromafield.xcodeproj
├── Chromafield/
│   ├── App/
│   │   ├── ChromafieldApp.swift          # @main entry, scene setup
│   │   └── ContentView.swift             # Root SwiftUI view — canvas + overlay composition
│   ├── Metal/
│   │   ├── Shaders/
│   │   │   ├── ParticleCompute.metal     # Compute kernel: force eval + velocity integration
│   │   │   ├── ParticleRender.metal      # Vertex + fragment: point sprites, trail accumulation
│   │   │   └── SharedTypes.metal         # Structs shared between Swift and Metal (bridging)
│   │   ├── MetalEngine.swift             # MTKViewDelegate, pipeline setup, triple-buffered render loop
│   │   ├── ParticleBuffer.swift          # MTLBuffer wrapper — initializes/owns particle state arrays
│   │   └── OffscreenRenderer.swift       # Export-mode renderer — renders frames to MTLTexture off-screen
│   ├── Simulation/
│   │   ├── FieldManager.swift            # Owns [FieldNodeModel], uploads GPU buffer each frame
│   │   ├── FieldNode.swift               # Model: type, position, strength, direction — Codable
│   │   ├── ParticleBehavior.swift        # Enum: flocking, diffusion, crystallization, orbital
│   │   └── SimulationConfig.swift        # Particle count budget, timestep, drag coefficient
│   ├── Input/
│   │   ├── GestureCoordinator.swift      # UIGestureRecognizer setup, routes events to FieldManager
│   │   ├── PencilInputHandler.swift      # Extracts force/azimuth/altitude from UITouch
│   │   └── InputMapper.swift             # Normalizes raw Pencil values to FieldNode parameters
│   ├── UI/
│   │   ├── CanvasContainerView.swift     # UIViewRepresentable wrapping MTKView
│   │   ├── RadialNodeMenu.swift          # SwiftUI radial picker for node type — appears at long-press
│   │   ├── BehaviorPicker.swift          # SwiftUI bottom sheet — 4 behavior options
│   │   ├── PaletteSelector.swift         # SwiftUI horizontal scroll — 8 palette swatches
│   │   ├── PresetGallery.swift           # SwiftUI sheet — thumbnail grid of presets + saved configs
│   │   └── ExportControls.swift          # SwiftUI sheet — PNG/MP4 export triggers + progress
│   ├── Persistence/
│   │   ├── PersistenceManager.swift      # Read/write FieldConfig JSON to Documents/configs/
│   │   └── FieldConfig.swift             # Codable: [FieldNodeModel] + behavior + palette + name
│   ├── Export/
│   │   ├── ImageExporter.swift           # MTLTexture → UIImage → PHPhotoLibrary / share sheet
│   │   └── VideoExporter.swift           # OffscreenRenderer frames → AVAssetWriter → Camera Roll
│   ├── Utilities/
│   │   ├── DeviceCapabilities.swift      # Detect device class via sysctl, return ParticleBudget
│   │   ├── FrameBudgetMonitor.swift      # Ring buffer of frame times, exposes isOverBudget
│   │   └── ColorPalette.swift            # 8 hardcoded palettes as [[SIMD4<Float>]]
│   └── Resources/
│       ├── Presets/                      # 6 bundled JSON preset FieldConfig files
│       └── Assets.xcassets
├── ChromafieldTests/
│   ├── SimulationTests.swift             # Headless Metal compute correctness (bounds, NaN, velocity)
│   ├── PersistenceTests.swift            # JSON encode/decode round-trip for FieldConfig
│   └── InputMapperTests.swift            # Pencil normalization unit tests
└── CLAUDE.md
```

### Core Data Structures

All structs in `SharedTypes.metal` are shared between Swift and Metal via the project's bridging header. Every struct must be 32-byte aligned. Assert sizes in `SimulationTests.swift`.

```metal
// SharedTypes.metal

struct Particle {
    float2 position;   // normalized [0,1] canvas coordinates
    float2 velocity;   // units/frame
    float4 color;      // RGBA, updated per frame via palette lookup
    float  age;        // frames since last reset
    float  lifetime;   // max frames before particle resets
    float  speed;      // cached length(velocity) for palette lerp
    float  padding;    // pad to 32 bytes
};
// MemoryLayout<Particle>.size must == 32

struct FieldNode {
    float2 position;   // normalized [0,1]
    float  strength;   // 0.0–1.0
    float  direction;  // radians (for flow vectors; unused by attractor/repeller)
    int    type;       // 0=attractor, 1=repeller, 2=vortex, 3=turbulence
    float  radius;     // influence falloff radius, normalized [0,1]
    float  falloff;    // force falloff exponent (1.0=linear, 2.0=quadratic)
    float  padding;    // pad to 32 bytes
};
// MemoryLayout<FieldNode>.size must == 32

struct SimParams {
    int   particleCount;
    int   fieldNodeCount;
    float deltaTime;
    int   behaviorMode;  // 0=flocking, 1=diffusion, 2=crystallization, 3=orbital
    float noiseScale;    // turbulence amplitude
    float cohesion;      // flocking: weight toward flock center
    float separation;    // flocking: weight away from neighbors
    float alignment;     // flocking: weight toward flock velocity
};
```

```swift
// Swift-side models (Codable for persistence, mirror Metal structs)

struct FieldNodeModel: Codable, Identifiable {
    let id: UUID
    var position: CGPoint        // converted to SIMD2<Float> before GPU upload
    var strength: Float          // 0.0–1.0
    var direction: Float         // radians
    var type: FieldNodeType
    var radius: Float            // default: 0.3
    var falloff: Float           // default: 1.5

    enum FieldNodeType: Int, Codable, CaseIterable {
        case attractor   = 0
        case repeller    = 1
        case vortex      = 2
        case turbulence  = 3

        var displayName: String {
            switch self {
            case .attractor:  return "Attract"
            case .repeller:   return "Repel"
            case .vortex:     return "Vortex"
            case .turbulence: return "Chaos"
            }
        }

        var systemImage: String {
            switch self {
            case .attractor:  return "arrow.down.circle"
            case .repeller:   return "arrow.up.and.away"
            case .vortex:     return "arrow.clockwise.circle"
            case .turbulence: return "wind"
            }
        }
    }
}

struct FieldConfig: Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var nodes: [FieldNodeModel]
    var behavior: ParticleBehavior
    var paletteIndex: Int         // 0–7
    var thumbnailData: Data?      // 200×200 PNG, generated on save
}

enum ParticleBehavior: Int, Codable, CaseIterable {
    case flocking        = 0
    case diffusion       = 1
    case crystallization = 2
    case orbital         = 3

    var displayName: String {
        switch self {
        case .flocking:        return "Flock"
        case .diffusion:       return "Diffuse"
        case .crystallization: return "Crystal"
        case .orbital:         return "Orbit"
        }
    }

    var description: String {
        switch self {
        case .flocking:        return "Particles align and move as a murmuration"
        case .diffusion:       return "Particles spread with Brownian drift"
        case .crystallization: return "Particles lock into geometric lattices"
        case .orbital:         return "Particles orbit attractors in rings"
        }
    }
}

struct ParticleBudget {
    let maxParticles: Int
    let exportScalePNG: Float    // 2.0 for all devices
    let exportScaleVideo: Float  // 1.0 iPhone, 2.0 iPad
    let targetFPS: Int           // always 60
}
```

### Color Palettes

8 curated palettes. Each palette is 4 SIMD4<Float> color stops: [slow-dim, slow-bright, fast-dim, fast-bright]. Particle color = bilinear lerp on (speed, age) axes.

```swift
// ColorPalette.swift
let palettes: [[SIMD4<Float>]] = [
    // 0: Ember — deep navy to white-hot orange
    [SIMD4(0.05, 0.05, 0.20, 1), SIMD4(0.60, 0.10, 0.05, 1),
     SIMD4(0.90, 0.40, 0.10, 1), SIMD4(1.00, 0.95, 0.80, 1)],
    // 1: Glacial — ice blue to white
    [SIMD4(0.02, 0.05, 0.15, 1), SIMD4(0.10, 0.30, 0.60, 1),
     SIMD4(0.40, 0.75, 0.95, 1), SIMD4(0.90, 0.97, 1.00, 1)],
    // 2: Void — deep purple to electric magenta
    [SIMD4(0.05, 0.00, 0.10, 1), SIMD4(0.25, 0.00, 0.50, 1),
     SIMD4(0.70, 0.00, 0.80, 1), SIMD4(1.00, 0.40, 1.00, 1)],
    // 3: Toxic — black to acid green
    [SIMD4(0.02, 0.05, 0.02, 1), SIMD4(0.05, 0.30, 0.05, 1),
     SIMD4(0.20, 0.80, 0.10, 1), SIMD4(0.80, 1.00, 0.20, 1)],
    // 4: Dusk — charcoal to rose gold
    [SIMD4(0.10, 0.08, 0.10, 1), SIMD4(0.40, 0.20, 0.25, 1),
     SIMD4(0.85, 0.50, 0.45, 1), SIMD4(1.00, 0.85, 0.70, 1)],
    // 5: Ocean — black to bioluminescent cyan
    [SIMD4(0.00, 0.02, 0.08, 1), SIMD4(0.00, 0.20, 0.40, 1),
     SIMD4(0.00, 0.70, 0.80, 1), SIMD4(0.60, 1.00, 0.95, 1)],
    // 6: Mono — pure grayscale
    [SIMD4(0.00, 0.00, 0.00, 1), SIMD4(0.20, 0.20, 0.20, 1),
     SIMD4(0.60, 0.60, 0.60, 1), SIMD4(1.00, 1.00, 1.00, 1)],
    // 7: Forge — deep red to molten gold
    [SIMD4(0.10, 0.00, 0.00, 1), SIMD4(0.50, 0.05, 0.00, 1),
     SIMD4(0.90, 0.40, 0.00, 1), SIMD4(1.00, 0.85, 0.30, 1)],
]

let paletteNames = ["Ember", "Glacial", "Void", "Toxic", "Dusk", "Ocean", "Mono", "Forge"]
```

### Device Capability Detection

```swift
// DeviceCapabilities.swift
// Use sysctl("hw.targettype") or UIDevice.current.model to classify chip tier.
// Never change particleCount mid-session — set once at launch.

func detectParticleBudget() -> ParticleBudget {
    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    let chip = detectChipTier()  // parse sysctl hw.targettype

    switch chip {
    case .m4:
        return ParticleBudget(maxParticles: 200_000,
                              exportScalePNG: 2.0,
                              exportScaleVideo: isIPad ? 2.0 : 1.0,
                              targetFPS: 60)
    case .m2, .m3:
        return ParticleBudget(maxParticles: 150_000,
                              exportScalePNG: 2.0,
                              exportScaleVideo: isIPad ? 2.0 : 1.0,
                              targetFPS: 60)
    case .m1:
        return ParticleBudget(maxParticles: 100_000,
                              exportScalePNG: 2.0,
                              exportScaleVideo: isIPad ? 2.0 : 1.0,
                              targetFPS: 60)
    case .a17, .a18:
        return ParticleBudget(maxParticles: 50_000,
                              exportScalePNG: 2.0,
                              exportScaleVideo: 1.0,
                              targetFPS: 60)
    default:
        return ParticleBudget(maxParticles: 20_000,
                              exportScalePNG: 1.0,
                              exportScaleVideo: 1.0,
                              targetFPS: 60)
    }
}
```

### Metal Compute Kernel — Core Logic

```metal
// ParticleCompute.metal
// Full implementation follows this pseudocode. Claude Code writes the complete kernel.

kernel void updateParticles(
    device   Particle*  particles  [[buffer(0)]],
    constant FieldNode* fieldNodes [[buffer(1)]],
    constant SimParams& params     [[buffer(2)]],
    uint index [[thread_position_in_grid]]
) {
    if (index >= uint(params.particleCount)) return;
    Particle p = particles[index];
    float2 totalForce = float2(0.0);

    for (int i = 0; i < params.fieldNodeCount; i++) {
        FieldNode node = fieldNodes[i];
        float2 delta = node.position - p.position;
        float dist = length(delta);
        if (dist < 0.001) continue;

        float influence = 1.0 - smoothstep(0.0, node.radius, dist);
        float forceMag  = node.strength * influence
                        * pow(1.0 / max(dist, 0.01), node.falloff);
        float2 dir = normalize(delta);

        switch (node.type) {
            case 0: totalForce += dir * forceMag; break;                      // attractor
            case 1: totalForce -= dir * forceMag; break;                      // repeller
            case 2: totalForce += float2(-dir.y, dir.x) * forceMag; break;   // vortex
            case 3: totalForce += hash2(p.position + float2(i, 0)) * forceMag; break; // turbulence
        }
    }

    // Behavior-specific velocity modifications applied after force summation
    // Diffusion: add small Brownian noise vector each frame
    // Crystallization: if speed < threshold, snap to nearest lattice point
    // Orbital: add perpendicular velocity component relative to nearest attractor
    // Flocking: reads from scratch neighbor buffer (second compute pass)

    p.velocity += totalForce * params.deltaTime;
    p.velocity *= 0.98;  // drag
    p.position += p.velocity * params.deltaTime;
    p.position  = fract(p.position + 1.0);  // wrap at boundaries

    p.age += 1.0;
    if (p.age > p.lifetime) {
        p.position = float2(hash(index + uint(p.age * 1000.0)),
                            hash(index + uint(p.age * 2000.0)));
        p.velocity = float2(0.0);
        p.age      = 0.0;
    }

    p.speed        = length(p.velocity);
    particles[index] = p;
}
```

**Flocking implementation note:** Boids requires two compute passes per frame:
- Pass 1: `buildNeighborGrid` — writes each particle's grid cell index to a scratch MTLBuffer using a spatial hash (grid cell = floor(position / cellSize))
- Pass 2: `applyFlocking` — for each particle, reads the 9 surrounding cells from the scratch buffer, computes cohesion/separation/alignment forces from neighbors within `separationRadius`
Never attempt a single-pass O(n²) neighbor scan at target particle counts.

### Bundled Presets

6 JSON files in `Resources/Presets/`. Each is a valid `FieldConfig` JSON. Load via `Bundle.main.url(forResource:withExtension:)`.

| File | Name | Behavior | Palette | Node Setup |
|------|------|----------|---------|------------|
| preset-nebula.json | Nebula | diffusion (1) | Ocean (5) | 3 attractors pos [(0.3,0.4),(0.6,0.5),(0.5,0.7)], 1 vortex pos [(0.5,0.5)] strength 0.6 |
| preset-crystal-web.json | Crystal Web | crystallization (2) | Glacial (1) | 5 attractors in regular pentagon, radius 0.25, strength 0.8 |
| preset-solar-wind.json | Solar Wind | flocking (0) | Ember (0) | 2 attractors pos [(0.2,0.5),(0.8,0.5)], 1 repeller pos [(0.5,0.5)] strength 0.4 |
| preset-void-dance.json | Void Dance | orbital (3) | Void (2) | 3 vortices at [(0.3,0.3),(0.7,0.3),(0.5,0.7)], alternating CW/CCW via direction field |
| preset-toxic-storm.json | Toxic Storm | diffusion (1) | Toxic (3) | 4 turbulence nodes at canvas corners, noiseScale 0.8 |
| preset-gold-rush.json | Gold Rush | orbital (3) | Forge (7) | 1 attractor pos [(0.5,0.5)] strength 1.0, 4 repellers in cross pattern radius 0.15 strength 0.7 |

### Export Pipeline

**PNG Export (`ImageExporter.swift`):**
1. Call `OffscreenRenderer.renderFrame(scale: budget.exportScalePNG)` → returns `MTLTexture`
2. Read pixels via `MTLTexture.getBytes(...)` into a `Data` buffer
3. Create `CGImage` from buffer → wrap in `UIImage`
4. Write to `PHPhotoLibrary` (request permission first if not granted)
5. Present `UIActivityViewController` for share sheet
- Field nodes: NOT rendered in export (OffscreenRenderer only runs ParticleRender pipeline, no node overlay)
- Target: < 3 seconds on iPad Pro M4 for a 2× resolution frame

**MP4 Export (`VideoExporter.swift`):**
1. Pause live simulation (set `isExporting = true` on MetalEngine)
2. Save current simulation state (particle positions/velocities)
3. Configure `AVAssetWriter` with H.264 codec, `AVVideoAVCCleanApertureKey`, 60fps
4. For each frame 0..<600 (10 seconds × 60fps):
   - Advance simulation by one fixed timestep (1/60s)
   - Call `OffscreenRenderer.renderFrame(scale: budget.exportScaleVideo)` → `MTLTexture`
   - Copy to `CVPixelBuffer` via `MTLTexture.getBytes`
   - Append to `AVAssetWriterInput`
   - Update `UIProgressView`: `Float(frame) / 600.0`
5. Finalize `AVAssetWriter`, write output URL to `PHPhotoLibrary`
6. Restore simulation state; set `isExporting = false`
- Target: < 30 seconds for 600 frames on iPad Pro M4

### Adaptive Quality

`FrameBudgetMonitor.swift` maintains a ring buffer of the last 60 frame times. If `averageFrameTimeMs > 14.0` for 10 consecutive frames:
1. Reduce `SimulationConfig.particleCount` by 10% (floor at 5,000)
2. Reallocate `ParticleBuffer` with new count
3. Show a 2-second toast: "Quality adjusted for performance"

Threshold: 14ms (leaves 2ms headroom for 60fps). Never increase particle count mid-session — adaptive quality only decrements.

---

## Scope Boundaries

**In scope (v1):**
- Metal compute particle simulation (attractor, repeller, vortex, turbulence field nodes)
- Apple Pencil input (pressure → strength, azimuth → direction for flow vectors)
- 4 particle behaviors: Flocking, Diffusion, Crystallization, Orbital
- 8 curated color palettes
- Trail accumulation render mode
- Field config save/load (JSON, local Documents directory)
- 6 bundled preset configs
- Preset gallery with thumbnails
- PNG export (2× resolution, Camera Roll + share sheet)
- MP4 export (10-second loop, non-realtime render, Camera Roll)
- Adaptive particle count (device capability + frame budget monitor)
- Universal app: iPad Pro + iPhone

**Out of scope (never in v1):**
- GIF export
- iCloud sync or any cloud storage
- Network requests of any kind
- Audio / sonification
- Any monetization, StoreKit, or analytics SDKs
- Social sharing integration beyond system share sheet
- Collaborative / multiplayer features
- Free color picker (curated palettes only)

**Deferred to v2:**
- Audio-reactive mode (mic input modulates field strength)
- Time-varying fields (nodes that pulse or oscillate)
- 4× resolution PNG export (iPad only)
- GIF export with palette quantization
- Wallpaper export as Live Photo

---

## Security & Credentials

- No credentials, no accounts, no network entitlements
- `NSPhotoLibraryAddUsageDescription` in Info.plist: "Chromafield saves your particle art to your photo library." — request only when user first triggers export
- User data (saved configs): app's local Documents directory, not iCloud-synced in v1
- No crash reporting SDK — use Xcode Organizer for App Store crash logs
- App Store privacy label: "No data collected"

---

## Phase 0: Metal Engine (Week 1)

**Objective:** Particle simulation runs correctly in a headless Metal compute pipeline. No UI. All correctness verified by XCTest.

**Tasks:**
1. Create Xcode project — Universal target (iPad + iPhone), iOS 17.0 deployment target, Swift 5.10, Metal enabled, add ChromafieldTests test target. — **Acceptance:** `xcodebuild build -scheme Chromafield` exits 0 with zero warnings.

2. Define `SharedTypes.metal` with `Particle`, `FieldNode`, `SimParams` structs. Add bridging header. Add size assertions to `SimulationTests.swift`: `XCTAssertEqual(MemoryLayout<Particle>.size, 32)`, `XCTAssertEqual(MemoryLayout<FieldNode>.size, 32)`. — **Acceptance:** `xcodebuild test` passes size assertions.

3. Implement `ParticleBuffer.swift` — wraps `MTLBuffer`, initializes N particles with random positions in [0,1] and zero velocity, exposes typed UnsafeMutablePointer. — **Acceptance:** Allocate 200,000 particles on M4 device without MTLBuffer error; all initial positions log within [0,1].

4. Implement `DeviceCapabilities.swift` — `detectParticleBudget()` returns correct `ParticleBudget` per device class. — **Acceptance:** Unit test: mock chip tier strings, assert correct `maxParticles` values per tier.

5. Implement `FrameBudgetMonitor.swift` — ring buffer (capacity 60), exposes `averageFrameTimeMs: Double` and `isOverBudget: Bool` (threshold: 14ms). — **Acceptance:** Unit test: push 60 values of 20.0ms, assert `isOverBudget == true`. Push 60 values of 10.0ms, assert `isOverBudget == false`.

6. Write `ParticleCompute.metal` — attractor, repeller, vortex, turbulence force evaluation + velocity integration + boundary wrap + particle aging/reset. No behavior modes yet. — **Acceptance:** See task 7.

7. Write `SimulationTests.swift` headless test: init `MetalEngine` with 100K particles + 3 attractors (positions [(0.2,0.2), (0.8,0.5), (0.5,0.8)], strength 0.5), run 300 compute frames via `commandBuffer.commit() + waitUntilCompleted()`, read back particle buffer, assert: (a) all `position.x` and `position.y` in [0,1], (b) all `speed` values < 10.0, (c) no NaN in any `position` or `velocity` component. — **Acceptance:** `xcodebuild test -scheme ChromafieldTests` passes all 3 assertions with 0 failures.

**Verification Checklist:**
- [ ] `xcodebuild build` → exit 0, zero warnings
- [ ] `xcodebuild test` → all tests pass (size assertions, device capability, frame budget, simulation correctness)
- [ ] No `MTLBuffer allocation failed` in console at 200K particles on target device

**Risks:**
- Swift/Metal struct alignment mismatch silently corrupts simulation → Mitigation: explicit `MemoryLayout` assertions in Phase 0 tests catch this before any UI is built
- MTLBuffer creation fails at 200K particles (6.4MB) → Mitigation: log allocation size; fallback max to 150K if OOM at runtime

---

## Phase 1: Interactive Canvas (Weeks 2–3)

**Objective:** MTKView renders particles live. User places/removes field nodes with finger or Pencil. Particles visibly respond. Radial node-type menu. Trail accumulation. Basic palette coloring.

**Tasks:**
1. Implement `MetalEngine.swift` as `MTKViewDelegate` — triple-buffered `MTLBuffer` rotation with `DispatchSemaphore(value: 3)`, compute pass + render pass per frame, draw call via `MTLRenderCommandEncoder` with point primitives. Canvas clears to black each frame (no trails yet). — **Acceptance:** 10,000 white point sprites visible and moving on `MTKView` in simulator; Xcode GPU frame capture shows frame time < 8ms at this count.

2. Implement `ParticleRender.metal` — vertex shader maps `particle.position` [0,1] to clip space; fragment shader outputs `particle.color`; point size 3.0px. Color is white for now (palette wired in task 7). — **Acceptance:** Particles visible as white dots; positions update each frame.

3. Implement `CanvasContainerView.swift` (`UIViewRepresentable` wrapping `MTKView`). Integrate into `ContentView.swift` as full-screen background layer with SwiftUI overlay on top. — **Acceptance:** Running app shows full-screen Metal canvas; no black gaps between canvas and screen edges on both iPad and iPhone.

4. Implement `FieldManager.swift` — owns `[FieldNodeModel]`, uploads to a `MTLBuffer` (max 64 nodes) each frame, notifies `MetalEngine` of `fieldNodeCount`. — **Acceptance:** Add 3 nodes programmatically; GPU buffer contains correct position/type data verified via frame capture buffer viewer.

5. Implement `GestureCoordinator.swift` — `UITapGestureRecognizer` (1 touch, 1 tap) → place default attractor at tap location; `UILongPressGestureRecognizer` (0.3s) → open radial menu at press location; `UITapGestureRecognizer` (2 touches) → delete nearest node within 44pt radius. Wire all recognizers to the underlying `UIView` in `CanvasContainerView`. — **Acceptance:** Single tap places attractor; particles stream toward it within 2 frames. Two-touch tap removes nearest node.

6. Implement `PencilInputHandler.swift` + `InputMapper.swift` — override `touchesBegan/Moved/Ended` in the `MTKView` subclass; extract `touch.force` (normalized 0–1 on Pencil) and `touch.azimuthAngle(in:)`; map to `strength = max(0.1, force)` and `direction = azimuthAngle`. Add debug overlay (toggle via triple-tap) showing raw and normalized values. — **Acceptance:** Light Pencil pressure → node strength ≈ 0.15; max pressure → strength ≈ 1.0. Debug overlay confirms values.

7. Implement `RadialNodeMenu.swift` — SwiftUI overlay appears at long-press CGPoint; 4 options arranged 90° apart (top=attractor, right=repeller, bottom=vortex, left=turbulence) with SF Symbol icon + label; dismiss on selection or tap-outside. Selection calls `FieldManager.addNode(type:at:strength:direction:)`. — **Acceptance:** Long-press opens menu; selecting "Vortex" places vortex node; particles rotate around it within 3 frames.

8. Wire palette-based particle coloring — pass `palettes[activePaletteIndex]` as a 4-element `MTLBuffer` uniform; in `ParticleRender.metal` fragment shader, lerp between palette stops based on `particle.speed` (normalized against `maxExpectedSpeed = 0.05`). Default palette: Ember (index 0). — **Acceptance:** Particles colored in orange/white tones matching Ember palette; fast particles brighter than slow particles.

9. Implement trail accumulation — replace per-frame clear with a persistent `MTLTexture` accumulation buffer; blend new particle render onto it each frame at 98% opacity (`sourceAlpha=1.0, destinationAlpha=0.98`); double-tap gesture clears accumulation buffer to black. — **Acceptance:** Particles leave visible trails that fade over ~2 seconds of inactivity. Double-tap clears all trails instantly.

**Verification Checklist:**
- [ ] 50,000 particles on iPad Pro (or simulator) — Xcode GPU report shows average frame time < 10ms
- [ ] Place all 4 node types; each produces visually distinct particle response
- [ ] Pencil: strong press creates visibly stronger field pull than feather press (test on physical device)
- [ ] Radial menu: opens at press location, all 4 types selectable, dismiss on tap-outside works
- [ ] Two-touch tap removes the nearest node; particles stop responding to that field
- [ ] Trails: visible, fading; double-tap clears cleanly

**Risks:**
- `UIGestureRecognizer` conflicts with SwiftUI — Mitigation: set `cancelsTouchesInView = false` on all recognizers; attach to the `MTKView`'s `UIView`, not the SwiftUI wrapper
- Triple-buffer `DispatchSemaphore` deadlock if signal/wait count goes negative → Mitigation: follow Apple's standard triple-buffer sample exactly; do not add custom semaphore logic

---

## Phase 2: Persistence, Presets, Behaviors (Week 4)

**Objective:** All 4 particle behaviors implemented and switchable. Field configs save/load. 6 bundled presets. Full palette selector UI.

**Tasks:**
1. Implement 4 behavior modes in `ParticleCompute.metal` — dispatched via `SimParams.behaviorMode`:
   - **Diffusion (1):** add `hash2(p.position + float2(frame)) * noiseScale * 0.001` to velocity each frame
   - **Crystallization (2):** if `length(p.velocity) < 0.0005`, compute nearest lattice point (`floor(p.position * 12.0) / 12.0`), move particle 5% toward it; zero velocity
   - **Orbital (3):** for each attractor, add `float2(-delta.y, delta.x) * forceMag * 0.5` (perpendicular to attraction direction)
   - **Flocking (0):** two-pass compute — Pass 1 `buildNeighborGrid` writes spatial grid cell index per particle; Pass 2 `applyFlocking` reads 9-cell neighborhood, applies cohesion (toward center of mass), separation (away from particles within 0.02), alignment (toward average velocity)
   — **Acceptance:** Each behavior produces visibly distinct motion from an identical 3-attractor configuration. Flocking shows murmuration-like streaming; Crystallization shows lattice snap; Orbital shows ring orbits; Diffusion shows Brownian scatter.

2. Implement `BehaviorPicker.swift` — SwiftUI `.sheet` with 4 buttons (behavior name + description text), detent `.medium`. Switching calls `MetalEngine.setBehavior(_:)` which updates `SimParams.behaviorMode` on the next frame — no simulation reset. — **Acceptance:** Switch from Flocking to Orbital mid-run; behavior change visible within 1 second; particle count unchanged.

3. Implement `FieldConfig.swift` (Codable) and `PersistenceManager.swift`:
   - `save(_ config: FieldConfig)` → encode to JSON, write to `Documents/configs/{config.id.uuidString}.json`, generate 200×200 thumbnail via `OffscreenRenderer` at scale 0.1
   - `loadAll()` → scan directory, decode all valid JSONs, return `[FieldConfig]` sorted by `createdAt` descending
   - `load(id: UUID)` → load single config by UUID filename
   - `delete(id: UUID)` → remove file
   — **Acceptance:** Save 5-node config; force-quit; relaunch; `PersistenceManager.loadAll()` returns 1 config with identical node count, positions (±0.001), types, behavior, palette.

4. Implement `PresetGallery.swift` — SwiftUI `.sheet` with two sections: "Presets" (6 bundled, non-deletable) and "Saved" (user configs, swipe-to-delete). Each cell shows 200×200 thumbnail + name. Tap loads config into `FieldManager` + updates `MetalEngine` behavior/palette. — **Acceptance:** Tap "Nebula" preset; canvas reconfigures to diffusion + Ocean palette + 4 nodes within 1 frame.

5. Create all 6 bundled preset JSON files in `Resources/Presets/`. Validate each decodes without error. — **Acceptance:** `PersistenceManager.loadBundledPresets()` returns 6 `FieldConfig` objects, all decode without throws.

6. Implement `PaletteSelector.swift` — horizontal `ScrollView` of 8 swatches (40×40pt gradient squares showing the 4 palette stops) with palette name below; selected swatch shows 2pt border. Tap updates `MetalEngine.activePaletteIndex`. — **Acceptance:** Switching palette changes particle colors within 1 frame; all 8 palettes visually distinct in the selector.

**Verification Checklist:**
- [ ] All 4 behaviors: visually distinct motion from identical field setup
- [ ] Flocking: no frame rate drop when switching from/to flocking (two-pass compute not causing stalls)
- [ ] Save → force quit → relaunch → load: exact field config restored
- [ ] All 6 presets load from bundle without decode errors
- [ ] Palette switching: instantaneous color change, all 8 palettes distinguishable

---

## Phase 3: Export + Polish + App Store (Weeks 5–6)

**Objective:** PNG and MP4 export working and tested on physical device. Adaptive quality implemented. UI polished. App Store submission complete.

**Tasks:**
1. Implement `OffscreenRenderer.swift` — creates an `MTLTexture` at `floor(screenSize * scale)` resolution, runs same `ParticleRender.metal` pipeline (no field node overlay) on the current particle buffer state, returns the texture. — **Acceptance:** `OffscreenRenderer.renderFrame(scale: 2.0)` returns a non-nil `MTLTexture` with `width == Int(screenWidth * 2)` on iPad Pro without GPU errors in console.

2. Implement `ImageExporter.swift`:
   - Request `PHPhotoLibrary` authorization if not yet granted (`.addOnly`)
   - Read MTLTexture pixels via `getBytes(_:bytesPerRow:region:mipmapLevel:)`
   - Create `CGImage` → `UIImage`
   - Write to Camera Roll via `PHPhotoLibrary.shared().performChanges`
   - Present `UIActivityViewController` for share sheet
   — **Acceptance:** On physical iPad Pro M4 — PNG appears in Camera Roll in < 3 seconds, resolution is exactly `2 × screenWidth` × `2 × screenHeight`, no field node indicators visible in image.

3. Implement `VideoExporter.swift`:
   - Set `MetalEngine.isExporting = true` (pauses interactive render loop)
   - Configure `AVAssetWriter` with `AVVideoCodecType.h264`, `AVVideoWidthKey/HeightKey` at export resolution, 60fps `AVVideoExpectedSourceFrameRateKey`
   - Loop 600 frames: advance simulation 1/60s, render to offscreen texture, copy to `CVPixelBuffer` via `MTLTexture.getBytes`, append to `AVAssetWriterInput`
   - Finalize writer, write to temp URL, save to `PHPhotoLibrary`
   - Report progress on main thread: `DispatchQueue.main.async { self.exportProgress = Float(frame) / 600.0 }`
   — **Acceptance:** On physical iPad Pro M4 — 10-second MP4 in Camera Roll in < 30 seconds; plays back at 60fps in Photos; no artifacts.

4. Implement `ExportControls.swift` — SwiftUI `.sheet` with two rows: "Save Image" (PNG) and "Record Loop" (MP4, 10 sec). MP4 row shows `ProgressView(value: exportProgress)` during export. Both rows disabled during active export. — **Acceptance:** Both export paths reachable; progress bar fills during video export; buttons re-enable after completion.

5. Implement adaptive quality in `MetalEngine` — after each frame, call `FrameBudgetMonitor.update(frameTimeMs)`. If `isOverBudget` for 10 consecutive frames, call `reduceParticleCount()`: multiply current count by 0.9, floor at 5,000, reallocate `ParticleBuffer`, show 2-second toast "Quality adjusted". — **Acceptance:** Manually force overrun (place 20 nodes on iPhone simulator); observe particle count toast and visible count decrement in HUD.

6. Add canvas HUD — small pill-shaped label (bottom-left, `text-xs`, 50% opacity) showing "N nodes · P particles". Tapping opens a settings sheet (particle count, current behavior, reset-all-nodes button). — **Acceptance:** HUD shows correct live values; updates within 1 frame of node add/remove.

7. App Store prep:
   - `Info.plist`: `NSPhotoLibraryAddUsageDescription` set
   - No network entitlements declared
   - App Icon: all required sizes in `Assets.xcassets`
   - Privacy manifest (`PrivacyInfo.xcprivacy`): no data collected, no tracking
   - App Store Connect: screenshots for 12.9" iPad and 6.7" iPhone (both required), app description, support URL, privacy policy URL (static "no data collected" page)
   — **Acceptance:** `xcodebuild archive` succeeds; App Store Connect upload passes automated validation with no errors.

**Verification Checklist:**
- [ ] PNG export: < 3 seconds on M4, correct 2× resolution, no node overlay
- [ ] MP4 export: < 30 seconds on M4, 10-second loop, plays in Photos at correct framerate
- [ ] Adaptive quality: particle count decrements under sustained overrun on constrained device
- [ ] HUD: correct live values, tap opens settings sheet
- [ ] `xcodebuild archive` → App Store Connect upload accepted, no binary rejections
- [ ] TestFlight build installs and runs on physical iPad Pro and iPhone

---

## Testing Strategy

### Automated (XCTest — run before every commit)
| Test File | What It Covers |
|-----------|----------------|
| `SimulationTests.swift` | Particle bounds [0,1], velocity magnitude < 10.0, no NaN after 300 frames |
| `DeviceCapabilityTests.swift` | `detectParticleBudget()` returns correct budgets per mocked chip tier |
| `FrameBudgetMonitorTests.swift` | `isOverBudget` detection from mocked frame time arrays |
| `PersistenceTests.swift` | `FieldConfig` encode/decode round-trip; all field types; JSON validity |
| `InputMapperTests.swift` | Pencil force 0.0 → strength 0.1; force 1.0 → strength 1.0; azimuth pass-through |

### Manual (physical device required)
| Phase | What To Test |
|-------|-------------|
| Phase 1 | Real Pencil pressure/tilt mapping (simulator sends force=1.0 always) |
| Phase 1 | All 4 node types: visual response accuracy |
| Phase 2 | Behavior switching under load (10+ nodes, max particles) |
| Phase 2 | Preset loading: all 6 presets, verify visual match to intent |
| Phase 3 | PNG export resolution on physical screen (measure pixel dimensions) |
| Phase 3 | MP4 export timing on M4 and on constrained iPhone |
| Phase 3 | Thermal throttle / adaptive quality on iPhone under 5-minute sustained load |
| Phase 3 | App Store screenshots: verify on physical devices, not simulator |

### Known Simulator Limitations
- Pencil force always returns `1.0` — all Pencil normalization testing requires physical device
- `PHPhotoLibrary` writes are slow/mocked on simulator — test export timing on device only
- Thermal throttling is not observable on simulator — adaptive quality testing requires device
