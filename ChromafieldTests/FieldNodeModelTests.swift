import XCTest
import simd
@testable import Chromafield

final class FieldNodeModelTests: XCTestCase {

    func testToFieldNodeConversion() {
        let model = FieldNodeModel(
            position: CGPoint(x: 0.3, y: 0.7),
            strength: 0.8,
            direction: 1.5,
            type: .vortex,
            radius: 0.4,
            falloff: 2.0
        )

        let fieldNode = model.toFieldNode()

        XCTAssertEqual(fieldNode.position.x, 0.3, accuracy: 0.001)
        XCTAssertEqual(fieldNode.position.y, 0.7, accuracy: 0.001)
        XCTAssertEqual(fieldNode.strength, 0.8, accuracy: 0.001)
        XCTAssertEqual(fieldNode.direction, 1.5, accuracy: 0.001)
        XCTAssertEqual(fieldNode.type, 2)  // vortex
        XCTAssertEqual(fieldNode.radius, 0.4, accuracy: 0.001)
        XCTAssertEqual(fieldNode.falloff, 2.0, accuracy: 0.001)
    }

    func testFieldNodeTypesHaveCorrectRawValues() {
        XCTAssertEqual(FieldNodeModel.FieldNodeType.attractor.rawValue, 0)
        XCTAssertEqual(FieldNodeModel.FieldNodeType.repeller.rawValue, 1)
        XCTAssertEqual(FieldNodeModel.FieldNodeType.vortex.rawValue, 2)
        XCTAssertEqual(FieldNodeModel.FieldNodeType.turbulence.rawValue, 3)
    }

    func testCodableRoundTrip() throws {
        let original = FieldNodeModel(
            position: CGPoint(x: 0.5, y: 0.5),
            strength: 0.6,
            direction: 0.0,
            type: .repeller,
            radius: 0.3,
            falloff: 1.5
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FieldNodeModel.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.position.x, original.position.x, accuracy: 0.001)
        XCTAssertEqual(decoded.position.y, original.position.y, accuracy: 0.001)
        XCTAssertEqual(decoded.strength, original.strength)
        XCTAssertEqual(decoded.type, original.type)
    }

    func testDefaultValues() {
        let node = FieldNodeModel(position: CGPoint(x: 0.5, y: 0.5))
        XCTAssertEqual(node.strength, 0.5)
        XCTAssertEqual(node.direction, 0)
        XCTAssertEqual(node.type, .attractor)
        XCTAssertEqual(node.radius, 0.3)
        XCTAssertEqual(node.falloff, 1.5)
    }
}
