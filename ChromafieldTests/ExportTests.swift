import XCTest
import Metal
@testable import Chromafield

@MainActor
final class ExportTests: XCTestCase {

    func testOffscreenRenderProducesCorrectDimensions() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)

        // Simulate a 2x export from a 375×812 screen
        let width = 750
        let height = 1624

        let renderer = OffscreenRenderer(engine: engine)
        let texture = renderer.renderFrame(width: width, height: height)

        XCTAssertNotNil(texture)
        XCTAssertEqual(texture?.width, width)
        XCTAssertEqual(texture?.height, height)
    }

    func testRenderSequenceProducesTexture() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)
        let nodes: [FieldNode] = [
            FieldNode(position: simd_float2(0.5, 0.5), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
        ]
        engine.setFieldNodes(nodes)

        let renderer = OffscreenRenderer(engine: engine)
        var lastProgress: Float = 0

        let texture = renderer.renderSequence(
            frames: 10,
            width: 200,
            height: 200,
            progress: { p in lastProgress = p }
        )

        XCTAssertNotNil(texture)
        XCTAssertEqual(lastProgress, 1.0, accuracy: 0.01,
                       "Progress should reach 1.0 after all frames")
    }
}
