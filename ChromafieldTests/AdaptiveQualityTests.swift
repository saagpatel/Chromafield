import XCTest
import Metal
@testable import Chromafield

@MainActor
final class AdaptiveQualityTests: XCTestCase {

    func testReduceParticleCountDecrementsBy10Percent() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 100_000)
        XCTAssertEqual(engine.particleCount, 100_000)

        engine.reduceParticleCount()

        XCTAssertEqual(engine.particleCount, 90_000,
                       "Should reduce by 10%")
    }

    func testReduceParticleCountFloorsAt5000() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 5000)
        engine.reduceParticleCount()

        XCTAssertEqual(engine.particleCount, 5000,
                       "Should not reduce below 5000")
    }

    func testReduceParticleCountUpdatesSimParams() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 10_000)
        engine.reduceParticleCount()

        XCTAssertEqual(engine.simParams.particleCount, Int32(engine.particleCount),
                       "simParams.particleCount should match engine.particleCount after reduction")
    }

    func testSimulationStillWorksAfterReduction() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 10_000)
        let nodes: [FieldNode] = [
            FieldNode(position: simd_float2(0.5, 0.5), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
        ]
        engine.setFieldNodes(nodes)

        engine.reduceParticleCount()

        // Run simulation after reduction
        for _ in 0..<50 {
            engine.step()
        }

        let particles = engine.readParticles()
        for i in 0..<engine.particleCount {
            let p = particles[i]
            XCTAssertFalse(p.position.x.isNaN || p.position.y.isNaN,
                           "No NaN after reduction at index \(i)")
        }
    }

    // MARK: - Particle State Save/Restore

    func testSaveRestoreParticleStateRoundTrip() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)

        // Run a few steps to create meaningful state
        let nodes: [FieldNode] = [
            FieldNode(position: simd_float2(0.5, 0.5), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
        ]
        engine.setFieldNodes(nodes)
        for _ in 0..<20 { engine.step() }

        // Snapshot positions before save
        let beforeSave = engine.readParticles()
        let savedPositions = (0..<1000).map { beforeSave[$0].position }

        // Save state
        guard let backup = engine.saveParticleState() else {
            XCTFail("saveParticleState returned nil")
            return
        }

        // Mutate state by running more steps
        for _ in 0..<50 { engine.step() }

        // Verify state has changed
        let afterMutation = engine.readParticles()
        var changed = false
        for i in 0..<1000 {
            if afterMutation[i].position.x != savedPositions[i].x {
                changed = true
                break
            }
        }
        XCTAssertTrue(changed, "Simulation should have changed particle positions")

        // Restore
        engine.restoreParticleState(backup)

        // Verify positions match the saved snapshot
        let afterRestore = engine.readParticles()
        for i in 0..<1000 {
            XCTAssertEqual(afterRestore[i].position.x, savedPositions[i].x, accuracy: 0.0001,
                           "Position.x should match saved state at index \(i)")
            XCTAssertEqual(afterRestore[i].position.y, savedPositions[i].y, accuracy: 0.0001,
                           "Position.y should match saved state at index \(i)")
        }
    }
}
