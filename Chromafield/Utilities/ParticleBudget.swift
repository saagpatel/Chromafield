import Foundation

struct ParticleBudget: Sendable {
    let maxParticles: Int
    let exportScalePNG: Float
    let exportScaleVideo: Float
    let targetFPS: Int
}
