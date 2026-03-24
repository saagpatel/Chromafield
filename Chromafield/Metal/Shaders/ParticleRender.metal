#include <metal_stdlib>
using namespace metal;
#include "SharedTypes.h"

// MARK: - Particle Render Pipeline

struct ParticleVertexOut {
    float4 position [[position]];
    float  pointSize [[point_size]];
    float  speed;
    float  ageRatio;
};

vertex ParticleVertexOut particleVertex(
    const device Particle* particles [[buffer(0)]],
    uint vid [[vertex_id]]
) {
    Particle p = particles[vid];

    ParticleVertexOut out;
    // Map [0,1] normalized → [-1,1] clip space
    // Negate Y because Metal clip space is Y-up but screen coords are Y-down
    out.position = float4(
        p.position.x * 2.0 - 1.0,
        -(p.position.y * 2.0 - 1.0),
        0.0,
        1.0
    );
    out.pointSize = 6.0;
    out.speed = p.speed;
    out.ageRatio = (p.lifetime > 0.0) ? clamp(p.age / p.lifetime, 0.0, 1.0) : 0.0;

    return out;
}

fragment float4 particleFragment(
    ParticleVertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]],
    constant float4* palette [[buffer(0)]],
    constant float& maxSpeed [[buffer(1)]]
) {
    // Circular point sprite — discard outside radius
    float2 delta = pointCoord - float2(0.5);
    float dist = length(delta);
    if (dist > 0.5) discard_fragment();

    // Soft edge falloff
    float alpha = 1.0 - smoothstep(0.3, 0.5, dist);

    // Bilinear palette interpolation: speed (slow→fast) × age (dim→bright)
    float t_speed = clamp(in.speed / maxSpeed, 0.0, 1.0);
    float t_age = in.ageRatio;

    // palette[0] = slow-dim, palette[1] = slow-bright
    // palette[2] = fast-dim, palette[3] = fast-bright
    float4 color0 = mix(palette[0], palette[1], t_age);
    float4 color1 = mix(palette[2], palette[3], t_age);
    float4 color = mix(color0, color1, t_speed);

    return float4(color.rgb, color.a * alpha);
}

// MARK: - Full-Screen Fade Pipeline (Trail Accumulation)

struct FadeVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex FadeVertexOut fadeVertex(uint vid [[vertex_id]]) {
    // Full-screen triangle from 3 vertices, no buffer needed
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    float2 texCoords[3] = {
        float2(0.0, 1.0),
        float2(2.0, 1.0),
        float2(0.0, -1.0)
    };

    FadeVertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 fadeFragment(
    FadeVertexOut in [[stage_in]],
    constant float& fadeAlpha [[buffer(0)]]
) {
    return float4(0.0, 0.0, 0.0, fadeAlpha);
}

// MARK: - Blit Pipeline (Copy accumulation texture to drawable)

fragment float4 blitFragment(
    FadeVertexOut in [[stage_in]],
    texture2d<float> sourceTexture [[texture(0)]]
) {
    constexpr sampler s(mag_filter::nearest, min_filter::nearest);
    return sourceTexture.sample(s, in.texCoord);
}
