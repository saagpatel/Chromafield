import MetalKit

final class MetalCanvasView: MTKView {
    var pencilHandler: PencilInputHandler?

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        commonInit()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func commonInit() {
        colorPixelFormat = .bgra8Unorm
        framebufferOnly = false
        preferredFramesPerSecond = 60
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        isPaused = false
        enableSetNeedsDisplay = false
        isMultipleTouchEnabled = true
    }

    // MARK: - Pencil Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch.type == .pencil {
            pencilHandler?.handleTouchBegan(touch, in: self)
            return
        }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch.type == .pencil {
            pencilHandler?.handleTouchMoved(touch, in: self)
            return
        }
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch.type == .pencil {
            pencilHandler?.handleTouchEnded(touch, in: self)
            return
        }
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch.type == .pencil {
            pencilHandler?.handleTouchEnded(touch, in: self)
            return
        }
        super.touchesCancelled(touches, with: event)
    }
}
