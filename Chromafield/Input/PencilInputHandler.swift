import UIKit

struct PencilDebugInfo: Sendable {
    let rawForce: CGFloat
    let rawAzimuth: CGFloat
    let mappedStrength: Float
    let mappedDirection: Float
}

@MainActor
final class PencilInputHandler: ObservableObject {
    private let fieldManager: FieldManager
    private var activeNodeID: UUID?

    @Published var debugInfo: PencilDebugInfo?
    @Published var isDebugOverlayVisible = false

    init(fieldManager: FieldManager) {
        self.fieldManager = fieldManager
    }

    func handleTouchBegan(_ touch: UITouch, in view: UIView) {
        let position = InputMapper.normalizedPosition(
            from: touch.location(in: view),
            in: view.bounds.size
        )
        let strength = InputMapper.mapStrength(
            force: touch.force,
            maximumForce: touch.maximumPossibleForce
        )
        let direction = InputMapper.mapDirection(azimuth: touch.azimuthAngle(in: view))
        let radius = InputMapper.mapRadius(altitude: touch.altitudeAngle)

        let node = FieldNodeModel(
            position: position,
            strength: strength,
            direction: direction,
            type: .attractor,
            radius: radius
        )
        fieldManager.addNode(node)
        activeNodeID = node.id

        updateDebugInfo(touch: touch, in: view, strength: strength, direction: direction)
    }

    func handleTouchMoved(_ touch: UITouch, in view: UIView) {
        guard let nodeID = activeNodeID else { return }

        let position = InputMapper.normalizedPosition(
            from: touch.location(in: view),
            in: view.bounds.size
        )
        fieldManager.moveNode(id: nodeID, to: position)

        let strength = InputMapper.mapStrength(
            force: touch.force,
            maximumForce: touch.maximumPossibleForce
        )
        let direction = InputMapper.mapDirection(azimuth: touch.azimuthAngle(in: view))

        // Update strength/direction on the moved node
        if fieldManager.nodes.contains(where: { $0.id == nodeID }) {
            fieldManager.updateNodeProperties(
                id: nodeID,
                strength: strength,
                direction: direction
            )
        }

        updateDebugInfo(touch: touch, in: view, strength: strength, direction: direction)
    }

    func handleTouchEnded(_ touch: UITouch, in view: UIView) {
        activeNodeID = nil
        debugInfo = nil
    }

    private func updateDebugInfo(touch: UITouch, in view: UIView, strength: Float, direction: Float) {
        guard isDebugOverlayVisible else { return }
        debugInfo = PencilDebugInfo(
            rawForce: touch.force,
            rawAzimuth: touch.azimuthAngle(in: view),
            mappedStrength: strength,
            mappedDirection: direction
        )
    }
}
