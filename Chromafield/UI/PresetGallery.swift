import SwiftUI

struct PresetGallery: View {
    let bundledPresets: [FieldConfig]
    let savedConfigs: [FieldConfig]
    let onLoad: (FieldConfig) -> Void
    let onDelete: (UUID) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Bundled presets
                    Section {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(bundledPresets) { config in
                                PresetCell(config: config) {
                                    onLoad(config)
                                }
                            }
                        }
                    } header: {
                        Text("Presets")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .textCase(.uppercase)
                    }

                    // Saved configs
                    Section {
                        if savedConfigs.isEmpty {
                            Text("No saved configurations yet")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(savedConfigs) { config in
                                    PresetCell(config: config) {
                                        onLoad(config)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            onDelete(config.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Saved")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .textCase(.uppercase)
                    }
                }
                .padding(16)
            }
            .background(.black)
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct PresetCell: View {
    let config: FieldConfig
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                thumbnailView
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(config.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = config.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Placeholder gradient from the config's palette
            let stops = config.paletteIndex < palettes.count
                ? palettes[config.paletteIndex]
                : palettes[0]

            LinearGradient(
                colors: stops.map { Color(
                    red: Double($0.x),
                    green: Double($0.y),
                    blue: Double($0.z)
                ) },
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        }
    }
}
