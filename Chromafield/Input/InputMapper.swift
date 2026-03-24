import Foundation

enum InputMapper: Sendable {
    /// Map pencil force to node strength [0.1, 1.0]
    static func mapStrength(force: CGFloat, maximumForce: CGFloat) -> Float {
        guard maximumForce > 0 else { return SimulationConfig.defaultNodeStrength }
        let normalized = Float(force / maximumForce)
        return max(0.1, min(1.0, normalized))
    }

    /// Map pencil azimuth angle to direction (radians, pass-through)
    static func mapDirection(azimuth: CGFloat) -> Float {
        Float(azimuth)
    }

    /// Map pencil altitude to influence radius
    /// Upright (altitude ≈ π/2) → narrow radius, flat (altitude ≈ 0) → wide radius
    static func mapRadius(altitude: CGFloat) -> Float {
        let normalized = Float(altitude / (.pi / 2))
        return 0.1 + (1.0 - normalized) * 0.4
    }

    /// Convert screen point to normalized [0,1] coordinates
    static func normalizedPosition(from point: CGPoint, in viewSize: CGSize) -> CGPoint {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }
        return CGPoint(
            x: point.x / viewSize.width,
            y: point.y / viewSize.height
        )
    }
}
