import UIKit

enum RadialMenuState: Equatable {
    case hidden
    case showing(at: CGPoint, normalized: CGPoint)

    static func == (lhs: RadialMenuState, rhs: RadialMenuState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden): true
        case (.showing(let a, _), .showing(let b, _)): a == b
        default: false
        }
    }
}

@MainActor
final class GestureCoordinator: NSObject, ObservableObject {
    private let fieldManager: FieldManager
    private weak var engine: MetalEngine?
    weak var canvasView: MetalCanvasView?

    @Published var radialMenuState: RadialMenuState = .hidden

    private var pendingNormalizedPosition: CGPoint = .zero

    init(fieldManager: FieldManager, engine: MetalEngine) {
        self.fieldManager = fieldManager
        self.engine = engine
        super.init()
    }

    func attachTo(view: UIView) {
        // Single tap — place default attractor
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.numberOfTouchesRequired = 1
        singleTap.numberOfTapsRequired = 1
        singleTap.cancelsTouchesInView = false

        // Double tap — clear trails
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false

        // Single tap waits for double tap to fail
        singleTap.require(toFail: doubleTap)

        // Long press — open radial menu
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.cancelsTouchesInView = false

        // Single tap waits for long press to fail
        singleTap.require(toFail: longPress)

        // Two-finger tap — delete nearest node
        let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleTwoFingerTap(_:)))
        twoFingerTap.numberOfTouchesRequired = 2
        twoFingerTap.numberOfTapsRequired = 1
        twoFingerTap.cancelsTouchesInView = false

        // Triple tap — toggle pencil debug
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap(_:)))
        tripleTap.numberOfTouchesRequired = 1
        tripleTap.numberOfTapsRequired = 3
        tripleTap.cancelsTouchesInView = false

        doubleTap.require(toFail: tripleTap)

        view.addGestureRecognizer(singleTap)
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(longPress)
        view.addGestureRecognizer(twoFingerTap)
        view.addGestureRecognizer(tripleTap)
    }

    // MARK: - Gesture Handlers

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let view = gesture.view else { return }
        let screenPoint = gesture.location(in: view)
        let normalized = InputMapper.normalizedPosition(from: screenPoint, in: view.bounds.size)

        fieldManager.addNode(FieldNodeModel(position: normalized))
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        engine?.clearAccumulationTexture()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let view = gesture.view else { return }
            let screenPoint = gesture.location(in: view)
            let normalized = InputMapper.normalizedPosition(from: screenPoint, in: view.bounds.size)
            radialMenuState = .showing(at: screenPoint, normalized: normalized)
        case .cancelled, .failed:
            radialMenuState = .hidden
        default:
            break
        }
    }

    @objc private func handleTwoFingerTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let view = gesture.view else { return }
        let screenPoint = gesture.location(in: view)
        let normalized = InputMapper.normalizedPosition(from: screenPoint, in: view.bounds.size)

        // 44pt radius converted to normalized distance
        let maxNormalizedDist = 44.0 / min(view.bounds.width, view.bounds.height)
        fieldManager.removeNearestNode(to: normalized, maxDistance: maxNormalizedDist)
    }

    @objc private func handleTripleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        if let pencil = canvasView?.pencilHandler {
            pencil.isDebugOverlayVisible.toggle()
        }
    }
}
