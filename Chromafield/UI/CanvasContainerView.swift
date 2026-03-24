import SwiftUI
import MetalKit

struct CanvasContainerView: UIViewRepresentable {
    let engine: MetalEngine
    let gestureCoordinator: GestureCoordinator
    let pencilHandler: PencilInputHandler

    func makeUIView(context: Context) -> MetalCanvasView {
        let mtkView = MetalCanvasView(frame: .zero, device: engine.device)
        mtkView.delegate = engine
        mtkView.pencilHandler = pencilHandler

        // Attach gesture recognizers
        gestureCoordinator.canvasView = mtkView
        gestureCoordinator.attachTo(view: mtkView)

        return mtkView
    }

    func updateUIView(_ uiView: MetalCanvasView, context: Context) {
        // No SwiftUI-driven updates needed — engine is the delegate
    }
}
