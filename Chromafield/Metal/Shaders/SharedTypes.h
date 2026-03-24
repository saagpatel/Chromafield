#ifndef SharedTypes_h
#define SharedTypes_h

#include <simd/simd.h>

struct Particle {
    simd_float2 position;   // normalized [0,1] canvas coordinates
    simd_float2 velocity;   // units/frame
    float       age;        // frames since last reset
    float       lifetime;   // max frames before particle resets
    float       speed;      // cached length(velocity) for palette lerp
    float       padding;    // pad to 32 bytes
};
// sizeof(Particle) must == 32

struct FieldNode {
    simd_float2 position;   // normalized [0,1]
    float       strength;   // 0.0–1.0
    float       direction;  // radians (for flow vectors; unused by attractor/repeller)
    int         type;       // 0=attractor, 1=repeller, 2=vortex, 3=turbulence
    float       radius;     // influence falloff radius, normalized [0,1]
    float       falloff;    // force falloff exponent (1.0=linear, 2.0=quadratic)
    float       padding;    // pad to 32 bytes
};
// sizeof(FieldNode) must == 32

struct SimParams {
    int   particleCount;
    int   fieldNodeCount;
    float deltaTime;
    int   behaviorMode;    // 0=flocking, 1=diffusion, 2=crystallization, 3=orbital
    float noiseScale;      // turbulence amplitude
    float cohesion;        // flocking: weight toward flock center
    float separation;      // flocking: weight away from neighbors
    float alignment;       // flocking: weight toward flock velocity
};
// sizeof(SimParams) must == 32

#endif
