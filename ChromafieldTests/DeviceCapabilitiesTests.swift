import XCTest
@testable import Chromafield

@MainActor
final class DeviceCapabilitiesTests: XCTestCase {

    func testM4Budget() {
        let budget = detectParticleBudget(chipTier: .m4)
        XCTAssertEqual(budget.maxParticles, 200_000)
        XCTAssertEqual(budget.exportScalePNG, 2.0)
        XCTAssertEqual(budget.targetFPS, 60)
    }

    func testM2M3Budget() {
        let budgetM2 = detectParticleBudget(chipTier: .m2)
        XCTAssertEqual(budgetM2.maxParticles, 150_000)

        let budgetM3 = detectParticleBudget(chipTier: .m3)
        XCTAssertEqual(budgetM3.maxParticles, 150_000)
    }

    func testM1Budget() {
        let budget = detectParticleBudget(chipTier: .m1)
        XCTAssertEqual(budget.maxParticles, 100_000)
    }

    func testASeriesBudget() {
        let budgetA17 = detectParticleBudget(chipTier: .a17)
        XCTAssertEqual(budgetA17.maxParticles, 50_000)
        XCTAssertEqual(budgetA17.exportScaleVideo, 1.0)

        let budgetA18 = detectParticleBudget(chipTier: .a18)
        XCTAssertEqual(budgetA18.maxParticles, 50_000)
    }

    func testUnknownChipFallsToMinimum() {
        let budget = detectParticleBudget(chipTier: .unknown)
        XCTAssertEqual(budget.maxParticles, 20_000)
        XCTAssertEqual(budget.exportScalePNG, 1.0)
        XCTAssertEqual(budget.exportScaleVideo, 1.0)
    }

    func testAllTiersTarget60FPS() {
        for tier in [ChipTier.m4, .m3, .m2, .m1, .a18, .a17, .a16, .a15, .unknown] {
            let budget = detectParticleBudget(chipTier: tier)
            XCTAssertEqual(budget.targetFPS, 60, "All tiers must target 60 FPS")
        }
    }
}
