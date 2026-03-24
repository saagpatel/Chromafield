import Foundation
import os

@MainActor
final class PersistenceManager {
    private let configsDirectory: URL
    private let logger = Logger(subsystem: "com.chromafield.app", category: "Persistence")

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let bundledPresetNames = [
        "preset-nebula",
        "preset-crystal-web",
        "preset-solar-wind",
        "preset-void-dance",
        "preset-toxic-storm",
        "preset-gold-rush",
    ]

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.configsDirectory = docs.appendingPathComponent("configs", isDirectory: true)
        try? FileManager.default.createDirectory(at: configsDirectory, withIntermediateDirectories: true)
    }

    func save(_ config: FieldConfig) throws {
        let data = try Self.encoder.encode(config)
        let fileURL = configsDirectory.appendingPathComponent("\(config.id.uuidString).json")
        try data.write(to: fileURL, options: .atomic)
        logger.info("Saved config '\(config.name)' to \(fileURL.lastPathComponent)")
    }

    func loadAll() -> [FieldConfig] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: configsDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        var configs: [FieldConfig] = []
        for url in contents where url.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: url)
                let config = try Self.decoder.decode(FieldConfig.self, from: data)
                configs.append(config)
            } catch {
                logger.warning("Skipping corrupt config at \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        return configs.sorted { $0.createdAt > $1.createdAt }
    }

    func load(id: UUID) throws -> FieldConfig {
        let fileURL = configsDirectory.appendingPathComponent("\(id.uuidString).json")
        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode(FieldConfig.self, from: data)
    }

    func delete(id: UUID) throws {
        let fileURL = configsDirectory.appendingPathComponent("\(id.uuidString).json")
        try FileManager.default.removeItem(at: fileURL)
        logger.info("Deleted config \(id.uuidString)")
    }

    func loadBundledPresets(bundle: Bundle? = nil) -> [FieldConfig] {
        let searchBundle = bundle ?? Bundle.main
        var presets: [FieldConfig] = []
        for name in bundledPresetNames {
            guard let url = searchBundle.url(forResource: name, withExtension: "json") else {
                logger.error("Bundled preset '\(name)' not found in bundle at \(searchBundle.bundlePath)")
                continue
            }
            do {
                let data = try Data(contentsOf: url)
                let config = try Self.decoder.decode(FieldConfig.self, from: data)
                presets.append(config)
            } catch {
                logger.error("Failed to decode bundled preset '\(name)': \(error)")
            }
        }
        return presets
    }
}
