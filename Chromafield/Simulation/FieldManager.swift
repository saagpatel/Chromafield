import Foundation

@MainActor
@Observable
final class FieldManager {
    private(set) var nodes: [FieldNodeModel] = []
    private let maxNodes = 64

    func addNode(_ node: FieldNodeModel) {
        guard nodes.count < maxNodes else { return }
        nodes.append(node)
    }

    func removeNode(id: UUID) {
        nodes.removeAll { $0.id == id }
    }

    @discardableResult
    func removeNearestNode(to point: CGPoint, maxDistance: CGFloat) -> Bool {
        var nearestIndex: Int?
        var nearestDist = CGFloat.greatestFiniteMagnitude

        for (i, node) in nodes.enumerated() {
            let dx = node.position.x - point.x
            let dy = node.position.y - point.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < nearestDist && dist <= maxDistance {
                nearestDist = dist
                nearestIndex = i
            }
        }

        if let index = nearestIndex {
            nodes.remove(at: index)
            return true
        }
        return false
    }

    func moveNode(id: UUID, to position: CGPoint) {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].position = position
    }

    func updateNodeProperties(id: UUID, strength: Float, direction: Float) {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].strength = strength
        nodes[index].direction = direction
    }

    func replaceNodes(_ newNodes: [FieldNodeModel]) {
        nodes = Array(newNodes.prefix(maxNodes))
    }

    func uploadToGPU(engine: MetalEngine) {
        let fieldNodes = nodes.map { $0.toFieldNode() }
        engine.setFieldNodes(fieldNodes)
    }
}
