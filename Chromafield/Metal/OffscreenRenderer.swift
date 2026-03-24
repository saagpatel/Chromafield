import Metal
import MetalKit
import UIKit

@MainActor
final class OffscreenRenderer {
    private let engine: MetalEngine
    private var offscreenAccumulation: MTLTexture?
    private var offscreenWidth = 0
    private var offscreenHeight = 0

    init(engine: MetalEngine) {
        self.engine = engine
    }

    // MARK: - Single Frame Render

    /// Renders the current particle state to a shared-mode texture at the given resolution.
    /// Does NOT advance the simulation — the caller is responsible for calling engine.step() first.
    func renderFrame(width: Int, height: Int) -> MTLTexture? {
        ensureAccumulationTexture(width: width, height: height)

        guard let accTexture = offscreenAccumulation,
              let renderPipeline = engine.renderPipelineState,
              let fadePipeline = engine.fadePipelineState,
              let blitPipeline = engine.blitPipelineState,
              let commandBuffer = engine.commandQueue.makeCommandBuffer() else { return nil }

        // Render particles to offscreen accumulation
        let accDesc = MTLRenderPassDescriptor()
        accDesc.colorAttachments[0].texture = accTexture
        accDesc.colorAttachments[0].loadAction = .load
        accDesc.colorAttachments[0].storeAction = .store

        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: accDesc) {
            // Fade existing trails
            encoder.setRenderPipelineState(fadePipeline)
            var fadeAlpha: Float = 0.02
            encoder.setFragmentBytes(&fadeAlpha, length: MemoryLayout<Float>.stride, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

            // Draw particles
            encoder.setRenderPipelineState(renderPipeline)
            encoder.setVertexBuffer(engine.particleBuffer.buffer, offset: 0, index: 0)

            if let palBuf = engine.paletteBuffer {
                encoder.setFragmentBuffer(palBuf, offset: 0, index: 0)
            }
            var speed = engine.maxExpectedSpeed
            encoder.setFragmentBytes(&speed, length: MemoryLayout<Float>.stride, index: 1)

            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: engine.particleCount)
            encoder.endEncoding()
        }

        // Blit accumulation to a shared readback texture
        let readbackTexture = createSharedTexture(width: width, height: height)
        guard let readback = readbackTexture else {
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            return nil
        }

        let blitDesc = MTLRenderPassDescriptor()
        blitDesc.colorAttachments[0].texture = readback
        blitDesc.colorAttachments[0].loadAction = .dontCare
        blitDesc.colorAttachments[0].storeAction = .store

        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: blitDesc) {
            encoder.setRenderPipelineState(blitPipeline)
            encoder.setFragmentTexture(accTexture, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return readback
    }

    /// Renders N frames with compute steps, building up trail accumulation.
    /// Calls engine.step() between each frame. Returns the final shared readback texture.
    func renderSequence(frames: Int, width: Int, height: Int,
                        progress: @escaping (Float) -> Void) -> MTLTexture? {
        clearAccumulation(width: width, height: height)

        for frame in 0..<frames {
            engine.step()

            guard let _ = renderFrame(width: width, height: height) else { return nil }

            progress(Float(frame + 1) / Float(frames))
        }

        // Final readback
        return renderFrame(width: width, height: height)
    }

    // MARK: - Texture Utilities

    static func textureToImage(texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        texture.getBytes(
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

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Private

    private func ensureAccumulationTexture(width: Int, height: Int) {
        if offscreenWidth == width, offscreenHeight == height,
           offscreenAccumulation != nil {
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

        offscreenAccumulation = engine.device.makeTexture(descriptor: desc)
        offscreenWidth = width
        offscreenHeight = height

        // Clear the new texture
        clearAccumulationNow()
    }

    private func clearAccumulation(width: Int, height: Int) {
        ensureAccumulationTexture(width: width, height: height)
        clearAccumulationNow()
    }

    private func clearAccumulationNow() {
        guard let texture = offscreenAccumulation,
              let commandBuffer = engine.commandQueue.makeCommandBuffer() else { return }

        let desc = MTLRenderPassDescriptor()
        desc.colorAttachments[0].texture = texture
        desc.colorAttachments[0].loadAction = .clear
        desc.colorAttachments[0].storeAction = .store
        desc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc) {
            encoder.endEncoding()
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func createSharedTexture(width: Int, height: Int) -> MTLTexture? {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        desc.storageMode = .shared
        desc.usage = [.renderTarget, .shaderRead]
        return engine.device.makeTexture(descriptor: desc)
    }
}
