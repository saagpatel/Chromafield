import XCTest
@testable import Chromafield

@MainActor
final class PresetDecodeTests: XCTestCase {

    private func findPresetBundle() -> Bundle {
        // In Xcode 26 hosted tests, resources live in the app bundle
        // Try multiple resolution strategies
        let candidates = [
            Bundle.main,
            Bundle(for: MetalEngine.self),
            Bundle(for: type(of: self)),
        ]
        for bundle in candidates {
            if bundle.url(forResource: "preset-nebula", withExtension: "json") != nil {
                return bundle
            }
        }
        // Last resort: walk the bundle path to find the .app
        if let appBundle = Bundle.allBundles.first(where: {
            $0.url(forResource: "preset-nebula", withExtension: "json") != nil
        }) {
            return appBundle
        }
        return Bundle.main
    }

    func testAllBundledPresetsDecodeSuccessfully() {
        let manager = PersistenceManager()
        let presets = manager.loadBundledPresets(bundle: findPresetBundle())
        XCTAssertEqual(presets.count, 6, "Should decode all 6 bundled presets")
    }

    func testPresetNodeCounts() {
        let manager = PersistenceManager()
        let presets = manager.loadBundledPresets(bundle: findPresetBundle())
        let countByName = Dictionary(uniqueKeysWithValues: presets.map { ($0.name, $0.nodes.count) })

        XCTAssertEqual(countByName["Nebula"], 4)
        XCTAssertEqual(countByName["Crystal Web"], 5)
        XCTAssertEqual(countByName["Solar Wind"], 3)
        XCTAssertEqual(countByName["Void Dance"], 3)
        XCTAssertEqual(countByName["Toxic Storm"], 4)
        XCTAssertEqual(countByName["Gold Rush"], 5)
    }

    func testPresetBehaviors() {
        let manager = PersistenceManager()
        let presets = manager.loadBundledPresets(bundle: findPresetBundle())
        let behaviorByName = Dictionary(uniqueKeysWithValues: presets.map { ($0.name, $0.behavior) })

        XCTAssertEqual(behaviorByName["Nebula"], .diffusion)
        XCTAssertEqual(behaviorByName["Crystal Web"], .crystallization)
        XCTAssertEqual(behaviorByName["Solar Wind"], .flocking)
        XCTAssertEqual(behaviorByName["Void Dance"], .orbital)
        XCTAssertEqual(behaviorByName["Toxic Storm"], .diffusion)
        XCTAssertEqual(behaviorByName["Gold Rush"], .orbital)
    }

    func testPresetPalettes() {
        let manager = PersistenceManager()
        let presets = manager.loadBundledPresets(bundle: findPresetBundle())
        let paletteByName = Dictionary(uniqueKeysWithValues: presets.map { ($0.name, $0.paletteIndex) })

        XCTAssertEqual(paletteByName["Nebula"], 5)       // Ocean
        XCTAssertEqual(paletteByName["Crystal Web"], 1)   // Glacial
        XCTAssertEqual(paletteByName["Solar Wind"], 0)    // Ember
        XCTAssertEqual(paletteByName["Void Dance"], 2)    // Void
        XCTAssertEqual(paletteByName["Toxic Storm"], 3)   // Toxic
        XCTAssertEqual(paletteByName["Gold Rush"], 7)     // Forge
    }
}
