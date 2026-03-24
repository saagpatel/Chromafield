import XCTest
@testable import Chromafield

@MainActor
final class FieldManagerTests: XCTestCase {

    func testAddNodeAppendsToCollection() {
        let manager = FieldManager()
        let node = FieldNodeModel(position: CGPoint(x: 0.5, y: 0.5))
        manager.addNode(node)

        XCTAssertEqual(manager.nodes.count, 1)
        XCTAssertEqual(manager.nodes.first?.id, node.id)
    }

    func testMaximum64NodesEnforced() {
        let manager = FieldManager()
        for i in 0..<70 {
            manager.addNode(FieldNodeModel(
                position: CGPoint(x: Double(i) / 70.0, y: 0.5)
            ))
        }
        XCTAssertEqual(manager.nodes.count, 64)
    }

    func testRemoveNodeById() {
        let manager = FieldManager()
        let node1 = FieldNodeModel(position: CGPoint(x: 0.2, y: 0.2))
        let node2 = FieldNodeModel(position: CGPoint(x: 0.8, y: 0.8))
        manager.addNode(node1)
        manager.addNode(node2)

        manager.removeNode(id: node1.id)

        XCTAssertEqual(manager.nodes.count, 1)
        XCTAssertEqual(manager.nodes.first?.id, node2.id)
    }

    func testRemoveNearestNodeWithinRadius() {
        let manager = FieldManager()
        let node = FieldNodeModel(position: CGPoint(x: 0.5, y: 0.5))
        manager.addNode(node)

        let removed = manager.removeNearestNode(
            to: CGPoint(x: 0.52, y: 0.52),
            maxDistance: 0.05
        )

        XCTAssertTrue(removed)
        XCTAssertTrue(manager.nodes.isEmpty)
    }

    func testRemoveNearestNodeOutsideRadiusReturnsFalse() {
        let manager = FieldManager()
        let node = FieldNodeModel(position: CGPoint(x: 0.5, y: 0.5))
        manager.addNode(node)

        let removed = manager.removeNearestNode(
            to: CGPoint(x: 0.9, y: 0.9),
            maxDistance: 0.05
        )

        XCTAssertFalse(removed)
        XCTAssertEqual(manager.nodes.count, 1)
    }

    func testRemoveNearestSelectsClosestAmongMultiple() {
        let manager = FieldManager()
        let far = FieldNodeModel(position: CGPoint(x: 0.1, y: 0.1))
        let close = FieldNodeModel(position: CGPoint(x: 0.51, y: 0.51))
        let medium = FieldNodeModel(position: CGPoint(x: 0.6, y: 0.6))
        manager.addNode(far)
        manager.addNode(close)
        manager.addNode(medium)

        let removed = manager.removeNearestNode(
            to: CGPoint(x: 0.5, y: 0.5),
            maxDistance: 0.2
        )

        XCTAssertTrue(removed)
        XCTAssertEqual(manager.nodes.count, 2)
        XCTAssertFalse(manager.nodes.contains(where: { $0.id == close.id }),
                       "Should remove the closest node, not another")
        XCTAssertTrue(manager.nodes.contains(where: { $0.id == far.id }))
        XCTAssertTrue(manager.nodes.contains(where: { $0.id == medium.id }))
    }

    func testMoveNode() {
        let manager = FieldManager()
        let node = FieldNodeModel(position: CGPoint(x: 0.2, y: 0.2))
        manager.addNode(node)

        manager.moveNode(id: node.id, to: CGPoint(x: 0.8, y: 0.8))

        XCTAssertEqual(manager.nodes.first?.position.x ?? 0, 0.8, accuracy: 0.001)
        XCTAssertEqual(manager.nodes.first?.position.y ?? 0, 0.8, accuracy: 0.001)
    }

    func testUpdateNodeProperties() {
        let manager = FieldManager()
        let node = FieldNodeModel(position: CGPoint(x: 0.5, y: 0.5))
        manager.addNode(node)

        manager.updateNodeProperties(id: node.id, strength: 0.9, direction: 1.57)

        XCTAssertEqual(manager.nodes.first?.strength, 0.9)
        XCTAssertEqual(manager.nodes.first?.direction ?? 0, 1.57, accuracy: 0.01)
    }

    func testReplaceNodes() {
        let manager = FieldManager()
        manager.addNode(FieldNodeModel(position: CGPoint(x: 0.1, y: 0.1)))
        manager.addNode(FieldNodeModel(position: CGPoint(x: 0.9, y: 0.9)))

        let newNodes = [
            FieldNodeModel(position: CGPoint(x: 0.3, y: 0.3)),
            FieldNodeModel(position: CGPoint(x: 0.5, y: 0.5)),
            FieldNodeModel(position: CGPoint(x: 0.7, y: 0.7)),
        ]
        manager.replaceNodes(newNodes)

        XCTAssertEqual(manager.nodes.count, 3)
        XCTAssertEqual(manager.nodes[0].id, newNodes[0].id)
        XCTAssertEqual(manager.nodes[1].id, newNodes[1].id)
        XCTAssertEqual(manager.nodes[2].id, newNodes[2].id)
    }
}
