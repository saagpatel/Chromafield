import XCTest
@testable import Chromafield

@MainActor
final class PersistenceTests: XCTestCase {
    private var manager: PersistenceManager!
    private var testConfigIDs: [UUID] = []

    override func setUp() {
        super.setUp()
        manager = PersistenceManager()
        testConfigIDs = []
    }

    override func tearDown() {
        // Clean up test configs
        for id in testConfigIDs {
            try? manager.delete(id: id)
        }
        super.tearDown()
    }

    private func makeConfig(
        name: String = "Test",
        date: Date = Date(),
        behavior: ParticleBehavior = .diffusion
    ) -> FieldConfig {
        let config = FieldConfig(
            name: name,
            createdAt: date,
            nodes: [
                FieldNodeModel(position: CGPoint(x: 0.5, y: 0.5), type: .attractor),
                FieldNodeModel(position: CGPoint(x: 0.3, y: 0.7), type: .vortex),
            ],
            behavior: behavior,
            paletteIndex: 2,
            noiseScale: 0.6
        )
        testConfigIDs.append(config.id)
        return config
    }

    func testSaveLoadRoundTrip() throws {
        let original = makeConfig(name: "Round Trip Test")
        try manager.save(original)

        let loaded = try manager.load(id: original.id)
        XCTAssertEqual(loaded.id, original.id)
        XCTAssertEqual(loaded.name, "Round Trip Test")
        XCTAssertEqual(loaded.nodes.count, 2)
        XCTAssertEqual(loaded.behavior, .diffusion)
        XCTAssertEqual(loaded.paletteIndex, 2)
        XCTAssertEqual(loaded.noiseScale, 0.6, accuracy: 0.001)
        XCTAssertEqual(loaded.nodes[0].position.x, 0.5, accuracy: 0.001)
    }

    func testLoadAllReturnsSortedByDate() throws {
        let old = makeConfig(name: "Old", date: Date(timeIntervalSince1970: 1000))
        let mid = makeConfig(name: "Mid", date: Date(timeIntervalSince1970: 2000))
        let recent = makeConfig(name: "Recent", date: Date(timeIntervalSince1970: 3000))

        try manager.save(old)
        try manager.save(recent)
        try manager.save(mid)

        let all = manager.loadAll()
        let testOnly = all.filter { testConfigIDs.contains($0.id) }
        XCTAssertGreaterThanOrEqual(testOnly.count, 3)

        // Verify sorted newest first
        let names = testOnly.prefix(3).map(\.name)
        XCTAssertEqual(names, ["Recent", "Mid", "Old"])
    }

    func testDeleteRemovesFile() throws {
        let config = makeConfig(name: "To Delete")
        try manager.save(config)

        try manager.delete(id: config.id)
        testConfigIDs.removeAll { $0 == config.id }

        let all = manager.loadAll()
        XCTAssertFalse(all.contains(where: { $0.id == config.id }))
    }

    func testCorruptJsonSkipped() throws {
        let config = makeConfig(name: "Good Config")
        try manager.save(config)

        // Write corrupt JSON to the configs directory
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let configsDir = docs.appendingPathComponent("configs")
        let corruptURL = configsDir.appendingPathComponent("corrupt.json")
        try "{ invalid json }}}".data(using: .utf8)!.write(to: corruptURL)

        let all = manager.loadAll()

        // Clean up corrupt file
        try? FileManager.default.removeItem(at: corruptURL)

        // Should still have at least the good config
        XCTAssertTrue(all.contains(where: { $0.id == config.id }),
                      "Good config should load even with corrupt file present")
    }
}
