import XCTest
@testable import Chromafield

final class InputMapperTests: XCTestCase {

    func testMapStrengthClampsToMinimum() {
        let strength = InputMapper.mapStrength(force: 0.0, maximumForce: 6.67)
        XCTAssertEqual(strength, 0.1, accuracy: 0.001)
    }

    func testMapStrengthClampsToMaximum() {
        let strength = InputMapper.mapStrength(force: 10.0, maximumForce: 6.67)
        XCTAssertEqual(strength, 1.0, accuracy: 0.001)
    }

    func testMapStrengthNormalizesCorrectly() {
        let strength = InputMapper.mapStrength(force: 3.335, maximumForce: 6.67)
        XCTAssertEqual(strength, 0.5, accuracy: 0.01)
    }

    func testMapStrengthZeroMaxReturnsDefault() {
        let strength = InputMapper.mapStrength(force: 1.0, maximumForce: 0)
        XCTAssertEqual(strength, SimulationConfig.defaultNodeStrength)
    }

    func testMapDirectionPassesThrough() {
        let direction = InputMapper.mapDirection(azimuth: 1.57)
        XCTAssertEqual(direction, 1.57, accuracy: 0.001)
    }

    func testMapRadiusUprightPencil() {
        // Altitude = π/2 (perpendicular to screen) → narrow radius
        let radius = InputMapper.mapRadius(altitude: .pi / 2)
        XCTAssertEqual(radius, 0.1, accuracy: 0.01)
    }

    func testMapRadiusFlatPencil() {
        // Altitude = 0 (parallel to screen) → wide radius
        let radius = InputMapper.mapRadius(altitude: 0)
        XCTAssertEqual(radius, 0.5, accuracy: 0.01)
    }

    func testNormalizedPosition() {
        let normalized = InputMapper.normalizedPosition(
            from: CGPoint(x: 200, y: 400),
            in: CGSize(width: 400, height: 800)
        )
        XCTAssertEqual(normalized.x, 0.5, accuracy: 0.001)
        XCTAssertEqual(normalized.y, 0.5, accuracy: 0.001)
    }

    func testNormalizedPositionZeroSizeReturnsZero() {
        let normalized = InputMapper.normalizedPosition(
            from: CGPoint(x: 100, y: 100),
            in: .zero
        )
        XCTAssertEqual(normalized, .zero)
    }
}
