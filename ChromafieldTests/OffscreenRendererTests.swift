import XCTest
import Metal
@testable import Chromafield

@MainActor
final class OffscreenRendererTests: XCTestCase {

    func testRenderFrameReturnsNonNilTexture() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)
        let renderer = OffscreenRenderer(engine: engine)

        let texture = renderer.renderFrame(width: 200, height: 200)
        XCTAssertNotNil(texture, "renderFrame should return a non-nil texture")
    }

    func testRenderFrameMatchesRequestedSize() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)
        let renderer = OffscreenRenderer(engine: engine)

        let texture = renderer.renderFrame(width: 400, height: 300)
        XCTAssertNotNil(texture)
        XCTAssertEqual(texture?.width, 400)
        XCTAssertEqual(texture?.height, 300)
    }

    func testTextureToImageProducesValidImage() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)
        // Run a few steps so particles have moved
        for _ in 0..<10 { engine.step() }

        let renderer = OffscreenRenderer(engine: engine)
        guard let texture = renderer.renderFrame(width: 200, height: 200) else {
            XCTFail("renderFrame returned nil")
            return
        }

        let image = OffscreenRenderer.textureToImage(texture: texture)
        XCTAssertNotNil(image, "textureToImage should produce a valid UIImage")
    }
}
