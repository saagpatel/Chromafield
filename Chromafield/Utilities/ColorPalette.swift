import simd

/// 8 curated palettes. Each palette is 4 SIMD4<Float> color stops:
/// [slow-dim, slow-bright, fast-dim, fast-bright]
/// Particle color = bilinear lerp on (speed, age) axes.
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
