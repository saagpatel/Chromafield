import XCTest
import Metal
import simd
@testable import Chromafield

@MainActor
final class SimulationTests: XCTestCase {

    // MARK: - Struct Size Assertions

    func testParticleSizeIs32Bytes() {
        XCTAssertEqual(MemoryLayout<Particle>.size, 32,
                       "Particle must be exactly 32 bytes for Metal buffer alignment")
        XCTAssertEqual(MemoryLayout<Particle>.stride, 32,
                       "Particle stride must equal size (no trailing padding)")
    }

    func testFieldNodeSizeIs32Bytes() {
        XCTAssertEqual(MemoryLayout<FieldNode>.size, 32,
                       "FieldNode must be exactly 32 bytes for Metal buffer alignment")
        XCTAssertEqual(MemoryLayout<FieldNode>.stride, 32,
                       "FieldNode stride must equal size (no trailing padding)")
    }

    func testSimParamsSizeIs32Bytes() {
        XCTAssertEqual(MemoryLayout<SimParams>.size, 32,
                       "SimParams must be exactly 32 bytes for Metal buffer alignment")
        XCTAssertEqual(MemoryLayout<SimParams>.stride, 32,
                       "SimParams stride must equal size (no trailing padding)")
    }

    // MARK: - Headless Simulation Correctness

    func testSimulation100KParticles300Frames() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available — cannot run GPU simulation test")
        }

        let particleCount = 100_000
        let frameCount = 300

        let engine = try MetalEngine(device: device, particleCount: particleCount)

        let nodes: [FieldNode] = [
            FieldNode(position: simd_float2(0.2, 0.2), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
            FieldNode(position: simd_float2(0.8, 0.5), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
            FieldNode(position: simd_float2(0.5, 0.8), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
        ]
        engine.setFieldNodes(nodes)

        for _ in 0..<frameCount {
            engine.step()
        }

        let particles = engine.readParticles()
        var nanCount = 0
        var outOfBoundsCount = 0
        var speedViolationCount = 0

        for i in 0..<particleCount {
            let p = particles[i]

            if p.position.x.isNaN || p.position.y.isNaN ||
               p.velocity.x.isNaN || p.velocity.y.isNaN ||
               p.speed.isNaN {
                nanCount += 1
            }

            if p.position.x < 0 || p.position.x >= 1.0 ||
               p.position.y < 0 || p.position.y >= 1.0 {
                outOfBoundsCount += 1
            }

            if p.speed >= 10.0 {
                speedViolationCount += 1
            }
        }

        XCTAssertEqual(nanCount, 0,
                       "No NaN values allowed in particle positions, velocities, or speed")
        XCTAssertEqual(outOfBoundsCount, 0,
                       "All particle positions must be in [0, 1)")
        XCTAssertEqual(speedViolationCount, 0,
                       "All particle speeds must be < 10.0")
    }

    // MARK: - Directional Correctness

    func testParticlesMoveTowardAttractor() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)

        let attractor = FieldNode(
            position: simd_float2(0.5, 0.5), strength: 0.8,
            direction: 0, type: 0, radius: 1.0, falloff: 1.0, padding: 0
        )
        engine.setFieldNodes([attractor])

        let before = engine.readParticles()
        var avgDistBefore: Float = 0
        for i in 0..<1000 {
            let dx = before[i].position.x - 0.5
            let dy = before[i].position.y - 0.5
            avgDistBefore += sqrt(dx * dx + dy * dy)
        }
        avgDistBefore /= 1000.0

        for _ in 0..<100 {
            engine.step()
        }

        let after = engine.readParticles()
        var avgDistAfter: Float = 0
        for i in 0..<1000 {
            let dx = after[i].position.x - 0.5
            let dy = after[i].position.y - 0.5
            avgDistAfter += sqrt(dx * dx + dy * dy)
        }
        avgDistAfter /= 1000.0

        XCTAssertLessThan(avgDistAfter, avgDistBefore,
                          "Particles should move closer to attractor on average")
    }

    // MARK: - Flocking Mode Correctness

    func testFlockingModeCorrectness() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 10_000)
        engine.simParams.behaviorMode = 0  // flocking

        let nodes: [FieldNode] = [
            FieldNode(position: simd_float2(0.3, 0.3), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
            FieldNode(position: simd_float2(0.7, 0.7), strength: 0.5,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.5, padding: 0),
        ]
        engine.setFieldNodes(nodes)

        for _ in 0..<100 {
            engine.step()
        }

        let particles = engine.readParticles()
        var nanCount = 0
        var outOfBoundsCount = 0

        for i in 0..<10_000 {
            let p = particles[i]
            if p.position.x.isNaN || p.position.y.isNaN || p.speed.isNaN {
                nanCount += 1
            }
            if p.position.x < 0 || p.position.x >= 1.0 ||
               p.position.y < 0 || p.position.y >= 1.0 {
                outOfBoundsCount += 1
            }
        }

        XCTAssertEqual(nanCount, 0, "Flocking mode should produce no NaN")
        XCTAssertEqual(outOfBoundsCount, 0, "Flocking particles should stay in [0,1)")
    }
}
