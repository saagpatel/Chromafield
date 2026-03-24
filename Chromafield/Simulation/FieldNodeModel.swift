import Foundation
import simd

struct FieldNodeModel: Identifiable, Codable, Sendable {
    let id: UUID
    var position: CGPoint
    var strength: Float
    var direction: Float
    var type: FieldNodeType
    var radius: Float
    var falloff: Float

    init(
        id: UUID = UUID(),
        position: CGPoint,
        strength: Float = 0.5,
        direction: Float = 0,
        type: FieldNodeType = .attractor,
        radius: Float = 0.3,
        falloff: Float = 1.5
    ) {
        self.id = id
        self.position = position
        self.strength = strength
        self.direction = direction
        self.type = type
        self.radius = radius
        self.falloff = falloff
    }

    func toFieldNode() -> FieldNode {
        FieldNode(
            position: simd_float2(Float(position.x), Float(position.y)),
            strength: strength,
            direction: direction,
            type: Int32(type.rawValue),
            radius: radius,
            falloff: falloff,
            padding: 0
        )
    }

    enum FieldNodeType: Int, Codable, CaseIterable, Sendable {
        case attractor   = 0
        case repeller    = 1
        case vortex      = 2
        case turbulence  = 3

        var displayName: String {
            switch self {
            case .attractor:  "Attract"
            case .repeller:   "Repel"
            case .vortex:     "Vortex"
            case .turbulence: "Chaos"
            }
        }

        var systemImage: String {
            switch self {
            case .attractor:  "arrow.down.circle"
            case .repeller:   "arrow.up.circle"
            case .vortex:     "arrow.clockwise.circle"
            case .turbulence: "wind"
            }
        }
    }
}
