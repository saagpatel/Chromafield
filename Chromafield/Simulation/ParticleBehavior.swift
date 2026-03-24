import Foundation

enum ParticleBehavior: Int, Codable, CaseIterable, Sendable {
    case flocking        = 0
    case diffusion       = 1
    case crystallization = 2
    case orbital         = 3

    var displayName: String {
        switch self {
        case .flocking:        "Flock"
        case .diffusion:       "Diffuse"
        case .crystallization: "Crystal"
        case .orbital:         "Orbit"
        }
    }

    var description: String {
        switch self {
        case .flocking:        "Particles align and move as a murmuration"
        case .diffusion:       "Particles spread with Brownian drift"
        case .crystallization: "Particles lock into geometric lattices"
        case .orbital:         "Particles orbit attractors in rings"
        }
    }
}
