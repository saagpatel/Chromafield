import Metal
import MetalKit
import simd
import UIKit

enum MetalEngineError: Error, CustomStringConvertible {
    case commandQueueCreationFailed
    case defaultLibraryNotFound
    case functionNotFound(String)
    case bufferAllocationFailed(String, Int)
    case pipelineCreationFailed(String)

    var description: String {
        switch self {
        case .commandQueueCreationFailed:
            "Failed to create Metal command queue"
        case .defaultLibraryNotFound:
            "Metal default library not found — ensure .metal files are in the target"
        case .functionNotFound(let name):
            "Metal function '\(name)' not found in default library"
        case .bufferAllocationFailed(let name, let bytes):
            "MTLBuffer allocation failed for \(name) (\(bytes) bytes)"
        case .pipelineCreationFailed(let detail):
            "Render pipeline creation failed: \(detail)"
        }
    }
}

@MainActor
final class MetalEngine: NSObject, MTKViewDelegate, ObservableObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let computePipeline: MTLComputePipelineState

    // Triple-buffered particle storage
    private var particleBuffers: [ParticleBuffer]
    private let bufferSemaphore = DispatchSemaphore(value: 3)
    private var frameIndex = 0
    private(set) var particleCount: Int

    // Field nodes
    let fieldNodeBuffer: MTLBuffer
    private let maxFieldNodes = 64
    var simParams: SimParams

    // Flocking spatial hash
    private let cellStartBuffer: MTLBuffer
    private var cellNextBuffer: MTLBuffer
    private let gridCellCount = 2500  // 50×50
    private let clearGridPipeline: MTLComputePipelineState
    private let buildGridPipeline: MTLComputePipelineState

    // Render pipelines (exposed for OffscreenRenderer)
    private(set) var renderPipelineState: MTLRenderPipelineState?
    private(set) var fadePipelineState: MTLRenderPipelineState?
    private(set) var blitPipelineState: MTLRenderPipelineState?

    // Palette
    private(set) var paletteBuffer: MTLBuffer?
    var activePaletteIndex: Int = 0 {
        didSet { updatePaletteBuffer() }
    }
    var maxExpectedSpeed: Float = 0.05

    // Trail accumulation
    private var accumulationTexture: MTLTexture?
    private var needsClearAccumulation = false

    // Export state
    var isExporting = false

    // Adaptive quality
    private var frameBudgetMonitor = FrameBudgetMonitor()
    private var consecutiveOverBudgetFrames = 0
    private let overBudgetThreshold = 10
    @Published var qualityReduced = false

    // External references
    var fieldManager: FieldManager?

    // MARK: - Backward compatibility for tests

    var particleBuffer: ParticleBuffer {
        particleBuffers[0]
    }

    // MARK: - Init

    init(device: MTLDevice, particleCount: Int) throws {
        self.device = device
        self.particleCount = particleCount

        guard let queue = device.makeCommandQueue() else {
            throw MetalEngineError.commandQueueCreationFailed
        }
        self.commandQueue = queue

        guard let library = device.makeDefaultLibrary() else {
            throw MetalEngineError.defaultLibraryNotFound
        }

        guard let computeFunction = library.makeFunction(name: "updateParticles") else {
            throw MetalEngineError.functionNotFound("updateParticles")
        }
        self.computePipeline = try device.makeComputePipelineState(function: computeFunction)

        // Flocking grid pipelines
        guard let clearFunction = library.makeFunction(name: "clearGrid") else {
            throw MetalEngineError.functionNotFound("clearGrid")
        }
        self.clearGridPipeline = try device.makeComputePipelineState(function: clearFunction)

        guard let buildFunction = library.makeFunction(name: "buildNeighborGrid") else {
            throw MetalEngineError.functionNotFound("buildNeighborGrid")
        }
        self.buildGridPipeline = try device.makeComputePipelineState(function: buildFunction)

        // Triple buffer allocation
        var buffers: [ParticleBuffer] = []
        for _ in 0..<3 {
            buffers.append(try ParticleBuffer(device: device, count: particleCount))
        }
        self.particleBuffers = buffers

        // Field node buffer
        let fieldBufferSize = maxFieldNodes * MemoryLayout<FieldNode>.stride
        guard let fieldBuffer = device.makeBuffer(length: fieldBufferSize, options: .storageModeShared) else {
            throw MetalEngineError.bufferAllocationFailed("fieldNodeBuffer", fieldBufferSize)
        }
        self.fieldNodeBuffer = fieldBuffer

        // Flocking grid buffers
        let cellStartSize = 2500 * MemoryLayout<Int32>.stride
        guard let csBuffer = device.makeBuffer(length: cellStartSize, options: .storageModeShared) else {
            throw MetalEngineError.bufferAllocationFailed("cellStartBuffer", cellStartSize)
        }
        self.cellStartBuffer = csBuffer

        let cellNextSize = particleCount * MemoryLayout<Int32>.stride
        guard let cnBuffer = device.makeBuffer(length: cellNextSize, options: .storageModeShared) else {
            throw MetalEngineError.bufferAllocationFailed("cellNextBuffer", cellNextSize)
        }
        self.cellNextBuffer = cnBuffer

        self.simParams = SimParams(
            particleCount: Int32(particleCount),
            fieldNodeCount: 0,
            deltaTime: 1.0 / 60.0,
            behaviorMode: 0,
            noiseScale: 0.5,
            cohesion: 0.3,
            separation: 0.5,
            alignment: 0.4
        )

        super.init()

        // Build render pipelines
        try configureRenderPipelines(library: library)
    }

    // MARK: - Pipeline Configuration

    private func configureRenderPipelines(library: MTLLibrary) throws {
        // Particle render pipeline
        let particleDesc = MTLRenderPipelineDescriptor()
        particleDesc.vertexFunction = library.makeFunction(name: "particleVertex")
        particleDesc.fragmentFunction = library.makeFunction(name: "particleFragment")
        particleDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Additive blending for particles
        particleDesc.colorAttachments[0].isBlendingEnabled = true
        particleDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        particleDesc.colorAttachments[0].destinationRGBBlendFactor = .one
        particleDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        particleDesc.colorAttachments[0].destinationAlphaBlendFactor = .one

        self.renderPipelineState = try device.makeRenderPipelineState(descriptor: particleDesc)

        // Fade pipeline (for trail darkening)
        let fadeDesc = MTLRenderPipelineDescriptor()
        fadeDesc.vertexFunction = library.makeFunction(name: "fadeVertex")
        fadeDesc.fragmentFunction = library.makeFunction(name: "fadeFragment")
        fadeDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Standard alpha blending for fade
        fadeDesc.colorAttachments[0].isBlendingEnabled = true
        fadeDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        fadeDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        fadeDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        fadeDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        self.fadePipelineState = try device.makeRenderPipelineState(descriptor: fadeDesc)

        // Blit pipeline (copy accumulation to drawable)
        let blitDesc = MTLRenderPipelineDescriptor()
        blitDesc.vertexFunction = library.makeFunction(name: "fadeVertex")
        blitDesc.fragmentFunction = library.makeFunction(name: "blitFragment")
        blitDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

        self.blitPipelineState = try device.makeRenderPipelineState(descriptor: blitDesc)
    }

    // MARK: - Field Nodes

    func setFieldNodes(_ nodes: [FieldNode]) {
        let count = min(nodes.count, maxFieldNodes)
        let pointer = fieldNodeBuffer.contents().bindMemory(to: FieldNode.self, capacity: maxFieldNodes)
        for i in 0..<count {
            pointer[i] = nodes[i]
        }
        simParams.fieldNodeCount = Int32(count)
    }

    // MARK: - Behaviors

    func setBehavior(_ behavior: ParticleBehavior) {
        simParams.behaviorMode = Int32(behavior.rawValue)
    }

    // MARK: - Palette

    func updatePaletteBuffer() {
        guard let paletteData = paletteDataForCurrentIndex() else { return }

        if paletteBuffer == nil {
            paletteBuffer = device.makeBuffer(
                length: 4 * MemoryLayout<SIMD4<Float>>.stride,
                options: .storageModeShared
            )
        }

        guard let buffer = paletteBuffer else { return }
        let pointer = buffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: 4)
        for i in 0..<4 {
            pointer[i] = paletteData[i]
        }
    }

    var paletteProvider: (() -> [SIMD4<Float>]?)?

    private func paletteDataForCurrentIndex() -> [SIMD4<Float>]? {
        paletteProvider?()
    }

    // MARK: - Accumulation Texture

    private func ensureAccumulationTexture(size: CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)

        if let existing = accumulationTexture,
           existing.width == width, existing.height == height {
            return
        }

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        desc.storageMode = .private
        desc.usage = [.renderTarget, .shaderRead]

        accumulationTexture = device.makeTexture(descriptor: desc)
        needsClearAccumulation = true
    }

    func clearAccumulationTexture() {
        needsClearAccumulation = true
    }

    // MARK: - Particle State Save/Restore (for video export)

    func saveParticleState() -> MTLBuffer? {
        let source = particleBuffers[0]
        let size = source.count * MemoryLayout<Particle>.stride
        guard let backup = device.makeBuffer(length: size, options: .storageModeShared) else { return nil }
        memcpy(backup.contents(), source.buffer.contents(), size)
        return backup
    }

    func restoreParticleState(_ backup: MTLBuffer) {
        let dest = particleBuffers[0]
        let size = dest.count * MemoryLayout<Particle>.stride
        memcpy(dest.buffer.contents(), backup.contents(), size)
    }

    // MARK: - Adaptive Quality

    private func recordFrameTime(_ ms: Double) {
        guard !isExporting else { return }
        frameBudgetMonitor.push(ms)
        if frameBudgetMonitor.isOverBudget {
            consecutiveOverBudgetFrames += 1
            if consecutiveOverBudgetFrames >= overBudgetThreshold {
                reduceParticleCount()
            }
        } else {
            consecutiveOverBudgetFrames = 0
        }
    }

    func reduceParticleCount() {
        let newCount = max(5000, Int(Double(particleCount) * 0.9))
        guard newCount < particleCount else { return }

        // Reallocate triple buffers, copying first N particles
        var newBuffers: [ParticleBuffer] = []
        for i in 0..<3 {
            guard let buf = try? ParticleBuffer(device: device, count: newCount) else { return }
            let copySize = newCount * MemoryLayout<Particle>.stride
            memcpy(buf.buffer.contents(), particleBuffers[i].buffer.contents(), copySize)
            newBuffers.append(buf)
        }
        particleBuffers = newBuffers
        particleCount = newCount
        simParams.particleCount = Int32(newCount)

        // Reallocate cellNext buffer for flocking
        let cellNextSize = newCount * MemoryLayout<Int32>.stride
        if let newCellNext = device.makeBuffer(length: cellNextSize, options: .storageModeShared) {
            cellNextBuffer = newCellNext
        }

        frameBudgetMonitor.reset()
        consecutiveOverBudgetFrames = 0
        qualityReduced = true
    }

    // MARK: - Thumbnail

    func renderThumbnail(size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        guard let accTexture = accumulationTexture,
              let blitPipeline = blitPipelineState else { return nil }

        let width = Int(size.width)
        let height = Int(size.height)

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        desc.storageMode = .shared
        desc.usage = [.renderTarget, .shaderRead]

        guard let thumbTexture = device.makeTexture(descriptor: desc),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }

        let renderDesc = MTLRenderPassDescriptor()
        renderDesc.colorAttachments[0].texture = thumbTexture
        renderDesc.colorAttachments[0].loadAction = .clear
        renderDesc.colorAttachments[0].storeAction = .store
        renderDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc) else { return nil }
        encoder.setRenderPipelineState(blitPipeline)
        encoder.setFragmentTexture(accTexture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let bytesPerRow = width * 4
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        thumbTexture.getBytes(
            &pixelData,
            bytesPerRow: bytesPerRow,
            from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                            size: MTLSize(width: width, height: height, depth: 1)),
            mipmapLevel: 0
        )

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue |
                              CGImageAlphaInfo.premultipliedFirst.rawValue
              ),
              let cgImage = context.makeImage() else { return nil }

        return UIImage(cgImage: cgImage).pngData()
    }

    // MARK: - Compute Helpers

    private func encodeFlockingGridPasses(commandBuffer: MTLCommandBuffer, particleBuffer: MTLBuffer) {
        guard let gridEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

        // Clear grid
        gridEncoder.setComputePipelineState(clearGridPipeline)
        gridEncoder.setBuffer(cellStartBuffer, offset: 0, index: 0)
        let clearThreads = min(gridCellCount, clearGridPipeline.maxTotalThreadsPerThreadgroup)
        gridEncoder.dispatchThreads(
            MTLSize(width: gridCellCount, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: clearThreads, height: 1, depth: 1)
        )

        // Build grid
        gridEncoder.setComputePipelineState(buildGridPipeline)
        gridEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        gridEncoder.setBuffer(cellStartBuffer, offset: 0, index: 1)
        gridEncoder.setBuffer(cellNextBuffer, offset: 0, index: 2)
        var gridParams = simParams
        gridEncoder.setBytes(&gridParams, length: MemoryLayout<SimParams>.stride, index: 3)
        let buildThreads = min(particleCount, buildGridPipeline.maxTotalThreadsPerThreadgroup)
        gridEncoder.dispatchThreads(
            MTLSize(width: particleCount, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: buildThreads, height: 1, depth: 1)
        )

        gridEncoder.endEncoding()
    }

    private func encodeParticleUpdate(commandBuffer: MTLCommandBuffer, particleBuffer: MTLBuffer) {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

        encoder.setComputePipelineState(computePipeline)
        encoder.setBuffer(particleBuffer, offset: 0, index: 0)
        encoder.setBuffer(fieldNodeBuffer, offset: 0, index: 1)

        var params = simParams
        encoder.setBytes(&params, length: MemoryLayout<SimParams>.stride, index: 2)
        encoder.setBuffer(cellStartBuffer, offset: 0, index: 3)
        encoder.setBuffer(cellNextBuffer, offset: 0, index: 4)

        let threadCount = particleCount
        let threadsPerGroup = min(threadCount, computePipeline.maxTotalThreadsPerThreadgroup)
        encoder.dispatchThreads(
            MTLSize(width: threadCount, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: threadsPerGroup, height: 1, depth: 1)
        )

        encoder.endEncoding()
    }

    // MARK: - Headless Compute (for tests)

    func step() {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let buffer = particleBuffers[0].buffer

        if simParams.behaviorMode == 0 {
            encodeFlockingGridPasses(commandBuffer: commandBuffer, particleBuffer: buffer)
        }

        encodeParticleUpdate(commandBuffer: commandBuffer, particleBuffer: buffer)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func readParticles() -> UnsafeBufferPointer<Particle> {
        let pointer = particleBuffers[0].buffer.contents().bindMemory(
            to: Particle.self, capacity: particleCount
        )
        return UnsafeBufferPointer(start: pointer, count: particleCount)
    }

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        MainActor.assumeIsolated {
            ensureAccumulationTexture(size: size)
        }
    }

    nonisolated func draw(in view: MTKView) {
        guard bufferSemaphore.wait(timeout: .now() + .milliseconds(100)) == .success else { return }

        MainActor.assumeIsolated {
            drawFrame(in: view)
        }
    }

    private func drawFrame(in view: MTKView) {
        frameIndex = (frameIndex + 1) % 3
        let currentBuffer = particleBuffers[frameIndex]

        fieldManager?.uploadToGPU(engine: self)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            bufferSemaphore.signal()
            return
        }

        let semaphore = bufferSemaphore
        commandBuffer.addCompletedHandler { [weak self] buf in
            semaphore.signal()
            let gpuTime = (buf.gpuEndTime - buf.gpuStartTime) * 1000.0
            if gpuTime > 0 {
                Task { @MainActor in
                    self?.recordFrameTime(gpuTime)
                }
            }
        }

        // --- Compute Pass (skip when exporting — VideoExporter drives sim via step()) ---
        if !isExporting {
            if simParams.behaviorMode == 0 {
                encodeFlockingGridPasses(commandBuffer: commandBuffer, particleBuffer: currentBuffer.buffer)
            }
            encodeParticleUpdate(commandBuffer: commandBuffer, particleBuffer: currentBuffer.buffer)
        }

        // Ensure accumulation texture exists
        ensureAccumulationTexture(size: view.drawableSize)

        guard let accTexture = accumulationTexture,
              let renderPipeline = renderPipelineState,
              let fadePipeline = fadePipelineState,
              let blitPipeline = blitPipelineState,
              let drawable = view.currentDrawable else {
            commandBuffer.commit()
            return
        }

        // --- Render to Accumulation Texture ---
        let accDesc = MTLRenderPassDescriptor()
        accDesc.colorAttachments[0].texture = accTexture
        accDesc.colorAttachments[0].loadAction = needsClearAccumulation ? .clear : .load
        accDesc.colorAttachments[0].storeAction = .store
        accDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        needsClearAccumulation = false

        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: accDesc) {
            // Fade pass: darken existing trails by 2%
            renderEncoder.setRenderPipelineState(fadePipeline)
            var fadeAlpha: Float = 0.02
            renderEncoder.setFragmentBytes(&fadeAlpha, length: MemoryLayout<Float>.stride, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

            // Particle pass: draw point sprites
            renderEncoder.setRenderPipelineState(renderPipeline)
            renderEncoder.setVertexBuffer(currentBuffer.buffer, offset: 0, index: 0)

            if let palBuf = paletteBuffer {
                renderEncoder.setFragmentBuffer(palBuf, offset: 0, index: 0)
            }
            var speed = maxExpectedSpeed
            renderEncoder.setFragmentBytes(&speed, length: MemoryLayout<Float>.stride, index: 1)

            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
            renderEncoder.endEncoding()
        }

        // --- Blit Accumulation to Drawable ---
        let presentDesc = MTLRenderPassDescriptor()
        presentDesc.colorAttachments[0].texture = drawable.texture
        presentDesc.colorAttachments[0].loadAction = .dontCare
        presentDesc.colorAttachments[0].storeAction = .store

        if let blitEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: presentDesc) {
            blitEncoder.setRenderPipelineState(blitPipeline)
            blitEncoder.setFragmentTexture(accTexture, index: 0)
            blitEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            blitEncoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
