# Chromafield — App Store Connect Metadata

> Submission-ready ASO copy. Every product claim below is verified against the
> shipping source (behaviors, node types, palettes, presets, particle budgets).
> Sanitized: no personal email, no API credentials, no local paths.

## Identity

| Field | Value |
|-------|-------|
| **Name** | Chromafield |
| **Subtitle** (30 char max) | `Particle art instrument` (23) |
| **Bundle ID** | com.chromafield.app |
| **SKU** | com.chromafield.app |
| **Primary Category** | Graphics & Design |
| **Secondary Category** | Entertainment |
| **Age Rating** | 4+ (see `privacy-and-age-rating.md`) |
| **Price** | Free (all territories) |
| **Copyright** | © 2026 Saagar Patel  *(set to your legal entity in ASC)* |
| **Support URL** | https://github.com/saagpatel/Chromafield/issues |
| **Privacy Policy URL** | https://github.com/saagpatel/Chromafield/blob/main/PRIVACY.md |

> **Note on category:** the existing live record uses *Entertainment* primary /
> *Graphics & Design* secondary. Recommendation flips these — *Graphics & Design*
> primary better matches a creative tool and faces lighter chart competition.
> Either is valid; pick one in ASC.

---

## Keywords (100 char limit)

Apple indexes **name + subtitle + keywords together**, so the keyword field must
NOT repeat words already in the name (`Chromafield`) or subtitle
(`particle`, `art`, `instrument`).

**Recommended (94 chars):**
```
generative,fluid,simulation,visualizer,sandbox,physics,abstract,relaxing,wallpaper,pencil,flow
```

**Alternate — current live value (94 chars):**
```
generative art,particles,Metal,creative,art,drawing,animation,abstract,instrument,Apple Pencil
```
*The alternate wastes slots on `art`/`particles`/`instrument` (already in subtitle)
and includes `Apple` (trademark term, low ranking value). The recommended set
trades those for higher-intent discovery terms.*

---

## Description

```
Chromafield is a particle art instrument. Place field nodes on a canvas — attractors, repellers, vortices, and chaos emitters — and watch thousands of particles respond in real time. Every placement is a brushstroke. Every configuration is a composition.

Built on Metal, Chromafield runs up to 200,000 particles at 60fps on the fastest iPads, scaling automatically to your device. The physics are real: particles are pulled, pushed, spun, and scattered by the forces you place. Apple Pencil pressure maps to field strength — a light touch creates gentle currents; full pressure warps the field.

FOUR PARTICLE BEHAVIORS
• Flock — particles align into murmurations, streaming like starlings
• Diffuse — particles drift with Brownian scatter, filling the canvas like ink in water
• Crystal — particles lock into geometric lattices, snapping to invisible grids
• Orbit — particles circle attractors in rings, forming solar-system structures

FOUR FIELD NODE TYPES
• Attractor — pulls particles toward a point with configurable falloff
• Repeller — pushes particles outward in a radial burst
• Vortex — rotates particles in a circular current
• Chaos — introduces turbulence, breaking ordered patterns apart

EIGHT CURATED PALETTES
Ember, Glacial, Void, Toxic, Dusk, Ocean, Mono, and Forge — each tuned so fast particles glow brighter than slow ones, giving the field energy and depth.

SAVE, LOAD, EXPORT
• Save field configurations and reload them anytime
• Six bundled presets to explore: Nebula, Crystal Web, Solar Wind, Void Dance, Toxic Storm, Gold Rush
• Export a full-resolution PNG to your photo library
• Export a 60fps MP4 loop, rendered offline for maximum quality
• Field nodes never appear in exports — only the particle art

No accounts. No cloud. No ads. No subscriptions. No tracking. Chromafield is entirely offline — your saved configurations live in local storage on your device, nothing more.

Works with finger and Apple Pencil on iPhone and iPad.
```

---

## Promotional Text (170 char max, updatable without a new version)

```
Place forces. Watch particles respond. Export the art. A Metal-powered generative art instrument for iPhone and iPad — fully offline, no accounts, no ads.
```

---

## What's New (release notes — v1.0)

```
Welcome to Chromafield 1.0.

Place field nodes, choose a particle behavior, and watch up to 200,000 particles respond in real time. Switch among eight curated palettes, explore six bundled presets, and export your work as a full-resolution PNG or a 60fps MP4 — all completely offline.

This is our first release. Questions or ideas? Reach us through the support link on this page.
```

---

## App Review Notes

```
Chromafield is a generative art tool. No login, no network requests, no accounts. The only permission requested is Photo Library "Add" — and only when the user first triggers an export, never at launch.

Core flow to test:
1. Launch — full-screen dark canvas with a default particle field.
2. Tap anywhere to place an attractor; particles stream toward it.
3. Long-press to open the radial node menu; choose Vortex and place it — particles rotate around it.
4. Use the palette selector to switch colors; use the behavior strip to switch Flock / Diffuse / Crystal / Orbit.
5. Open the gallery and load "Nebula" — the canvas reconfigures immediately.
6. Tap export → "Save Image" to write a PNG (this triggers the one-time Photo Library Add prompt).

Apple Pencil maps pressure to field-node strength, but every feature works with finger input. No reviewer account, credentials, or network connectivity required.
```

---

## Source-of-truth note

The live ASC text fields and `fastlane/metadata/en-US/` are the upload sources used
by `fastlane deliver`. This file is the human-readable canonical packet — keep the
two in sync when copy changes. Screenshot sizes and the capture plan live in
`screenshots.md`; privacy and age-rating answers in `privacy-and-age-rating.md`.
