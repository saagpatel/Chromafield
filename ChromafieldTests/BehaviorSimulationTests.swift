import XCTest
import Metal
import simd
@testable import Chromafield

@MainActor
final class BehaviorSimulationTests: XCTestCase {

    func testDiffusionAddsNoise() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)
        engine.simParams.behaviorMode = 1  // diffusion
        engine.simParams.noiseScale = 0.5

        // No field nodes — only Brownian noise drives motion
        for _ in 0..<100 {
            engine.step()
        }

        let particles = engine.readParticles()
        var totalSpeed: Float = 0
        for i in 0..<1000 {
            totalSpeed += particles[i].speed
        }
        let avgSpeed = totalSpeed / 1000.0

        XCTAssertGreaterThan(avgSpeed, 0, "Diffusion should create motion even without field nodes")
    }

    func testCrystallizationConverges() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 1000)
        engine.simParams.behaviorMode = 2  // crystallization

        let nodes: [FieldNode] = [
            FieldNode(position: simd_float2(0.5, 0.5), strength: 0.3,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.0, padding: 0),
        ]
        engine.setFieldNodes(nodes)

        for _ in 0..<500 {
            engine.step()
        }

        let particles = engine.readParticles()
        var stoppedCount = 0
        for i in 0..<1000 {
            if particles[i].speed < 0.001 {
                stoppedCount += 1
            }
        }

        XCTAssertGreaterThan(stoppedCount, 0,
                             "Some particles should have snapped to lattice (speed ≈ 0)")
    }

    func testOrbitalProducesBoundedMotion() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available")
        }

        let engine = try MetalEngine(device: device, particleCount: 10_000)
        engine.simParams.behaviorMode = 3  // orbital

        let nodes: [FieldNode] = [
            FieldNode(position: simd_float2(0.5, 0.5), strength: 0.8,
                      direction: 0, type: 0, radius: 0.5, falloff: 1.0, padding: 0),
        ]
        engine.setFieldNodes(nodes)

        for _ in 0..<100 {
            engine.step()
        }

        let particles = engine.readParticles()
        for i in 0..<10_000 {
            let p = particles[i]
            XCTAssertFalse(p.position.x.isNaN || p.position.y.isNaN,
                           "Orbital should not produce NaN")
            XCTAssertTrue(p.position.x >= 0 && p.position.x < 1.0,
                          "Orbital particle out of bounds at index \(i)")
        }
    }

    func testFlockingWithSpatialHash() throws {
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

        for _ in 0..<300 {
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

        XCTAssertEqual(nanCount, 0, "Flocking should produce no NaN values")
        XCTAssertEqual(outOfBoundsCount, 0, "All flocking particles should be in [0, 1)")
    }
}
