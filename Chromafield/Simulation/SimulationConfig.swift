import Foundation

enum SimulationConfig {
    static let maxExpectedSpeed: Float = 0.05
    static let dragCoefficient: Float = 0.98
    static let defaultPointSize: Float = 6.0
    static let defaultNodeRadius: Float = 0.3
    static let defaultNodeFalloff: Float = 1.5
    static let defaultNodeStrength: Float = 0.5
    static let frameBudgetThresholdMs: Double = 14.0
    static let trailFadeAlpha: Float = 0.02
}
