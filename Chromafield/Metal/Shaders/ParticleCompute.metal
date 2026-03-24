#include <metal_stdlib>
using namespace metal;
#include "SharedTypes.h"

// GPU-friendly hash — Dave Hoskins "Hash without Sine"
// Uses only fract/dot/multiply — bitwise deterministic across Apple GPUs.

static float hash11(float p) {
    float3 p3 = fract(float3(p) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float hash_uint(uint n) {
    n = (n << 13u) ^ n;
    n = n * (n * n * 15731u + 789221u) + 1376312589u;
    return float(n & 0x7fffffffu) / float(0x7fffffff);
}

static float2 hash2(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

// MARK: - Flocking spatial hash kernels

kernel void clearGrid(
    device atomic_int* cellStart [[buffer(0)]],
    uint index [[thread_position_in_grid]]
) {
    atomic_store_explicit(&cellStart[index], -1, memory_order_relaxed);
}

kernel void buildNeighborGrid(
    device Particle*    particles  [[buffer(0)]],
    device atomic_int*  cellStart  [[buffer(1)]],
    device int*         cellNext   [[buffer(2)]],
    constant SimParams& params     [[buffer(3)]],
    uint index [[thread_position_in_grid]]
) {
    if (index >= uint(params.particleCount)) return;

    Particle p = particles[index];
    int cellX = clamp(int(p.position.x * 50.0), 0, 49);
    int cellY = clamp(int(p.position.y * 50.0), 0, 49);
    int cellIdx = cellY * 50 + cellX;

    int prev = atomic_exchange_explicit(&cellStart[cellIdx], int(index), memory_order_relaxed);
    cellNext[index] = prev;
}

// MARK: - Main particle update kernel

kernel void updateParticles(
    device   Particle*  particles  [[buffer(0)]],
    constant FieldNode* fieldNodes [[buffer(1)]],
    constant SimParams& params     [[buffer(2)]],
    device int*         cellStart  [[buffer(3)]],
    device int*         cellNext   [[buffer(4)]],
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
        float rawForceMag = node.strength * influence
                          * pow(1.0 / max(dist, 0.01), node.falloff);
        float forceMag = min(rawForceMag, 2.0);
        float2 dir = normalize(delta);

        switch (node.type) {
            case 0:  // attractor
                totalForce += dir * forceMag;
                break;
            case 1:  // repeller
                totalForce -= dir * forceMag;
                break;
            case 2: {  // vortex — direction sign controls CW/CCW
                float sign = (node.direction >= 0.0) ? 1.0 : -1.0;
                totalForce += float2(-dir.y, dir.x) * sign * forceMag;
                break;
            }
            case 3:  // turbulence
                totalForce += hash2(p.position * params.noiseScale + float2(float(i), 0.0)) * forceMag;
                break;
            default:
                break;
        }
    }

    // Behavior-specific modifications (after force summation, before velocity integration)
    switch (params.behaviorMode) {
        case 0: {  // flocking — boids via spatial hash
            int cellX = clamp(int(p.position.x * 50.0), 0, 49);
            int cellY = clamp(int(p.position.y * 50.0), 0, 49);
            float2 cohesionSum = float2(0.0);
            float2 separationSum = float2(0.0);
            float2 alignmentSum = float2(0.0);
            int neighborCount = 0;

            for (int dy = -1; dy <= 1; dy++) {
                for (int dx = -1; dx <= 1; dx++) {
                    int nx = cellX + dx;
                    int ny = cellY + dy;
                    if (nx < 0 || nx >= 50 || ny < 0 || ny >= 50) continue;
                    int pIdx = cellStart[ny * 50 + nx];
                    int maxIter = 32;
                    while (pIdx >= 0 && maxIter-- > 0) {
                        if (uint(pIdx) != index) {
                            Particle other = particles[pIdx];
                            float2 diff = other.position - p.position;
                            float d = length(diff);
                            if (d < 0.02 && d > 0.0001) {
                                cohesionSum += other.position;
                                separationSum -= diff / d;
                                alignmentSum += other.velocity;
                                neighborCount++;
                            }
                        }
                        pIdx = cellNext[pIdx];
                    }
                }
            }
            if (neighborCount > 0) {
                float invN = 1.0 / float(neighborCount);
                totalForce += (cohesionSum * invN - p.position) * params.cohesion;
                totalForce += separationSum * invN * params.separation;
                totalForce += (alignmentSum * invN - p.velocity) * params.alignment;
            }
            break;
        }
        case 1: {  // diffusion — Brownian noise
            float2 noise = hash2(p.position + float2(p.age, p.age * 0.7))
                          * params.noiseScale * 0.001;
            p.velocity += noise;
            break;
        }
        case 2: {  // crystallization — lattice snap when slow
            if (length(p.velocity) < 0.0005) {
                float2 lattice = floor(p.position * 12.0) / 12.0;
                p.position = mix(p.position, lattice, 0.05);
                p.velocity = float2(0.0);
            }
            break;
        }
        case 3: {  // orbital — perpendicular force around attractors
            for (int i = 0; i < params.fieldNodeCount; i++) {
                FieldNode node = fieldNodes[i];
                if (node.type != 0) continue;
                float2 delta = node.position - p.position;
                float dist = length(delta);
                if (dist < 0.001) continue;
                float influence = 1.0 - smoothstep(0.0, node.radius, dist);
                float orbMag = min(node.strength * influence
                             * pow(1.0 / max(dist, 0.01), node.falloff), 2.0);
                totalForce += float2(-delta.y, delta.x) / dist * orbMag * 0.5;
            }
            break;
        }
        default:
            break;
    }

    // Velocity integration
    p.velocity += totalForce * params.deltaTime;
    p.velocity *= 0.98;  // drag coefficient
    p.velocity = clamp(p.velocity, float2(-1.0), float2(1.0));

    // Position integration + boundary wrapping
    p.position += p.velocity * params.deltaTime;
    p.position = fract(p.position + float2(1.0));

    // Aging and reset
    p.age += 1.0;
    if (p.age > p.lifetime) {
        p.position = float2(
            hash_uint(index * 2u + uint(p.age)),
            hash_uint(index * 2u + 1u + uint(p.age))
        );
        p.velocity = float2(0.0);
        p.age = 0.0;
        p.lifetime = 120.0 + hash11(float(index) + p.lifetime) * 480.0;
    }

    // Cache speed for render shader palette lookup
    p.speed = length(p.velocity);

    particles[index] = p;
}
