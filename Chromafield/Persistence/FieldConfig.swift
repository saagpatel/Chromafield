import Foundation

struct FieldConfig: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var createdAt: Date
    var nodes: [FieldNodeModel]
    var behavior: ParticleBehavior
    var paletteIndex: Int
    var noiseScale: Float
    var thumbnailData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        nodes: [FieldNodeModel],
        behavior: ParticleBehavior,
        paletteIndex: Int,
        noiseScale: Float = 0.5,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.nodes = nodes
        self.behavior = behavior
        self.paletteIndex = paletteIndex
        self.noiseScale = noiseScale
        self.thumbnailData = thumbnailData
    }

    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, nodes, behavior, paletteIndex, noiseScale, thumbnailData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        nodes = try container.decode([FieldNodeModel].self, forKey: .nodes)
        behavior = try container.decode(ParticleBehavior.self, forKey: .behavior)
        paletteIndex = try container.decode(Int.self, forKey: .paletteIndex)
        noiseScale = try container.decodeIfPresent(Float.self, forKey: .noiseScale) ?? 0.5
        thumbnailData = try container.decodeIfPresent(Data.self, forKey: .thumbnailData)
    }
}
