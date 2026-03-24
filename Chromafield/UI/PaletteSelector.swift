import SwiftUI

struct PaletteSelector: View {
    let activePaletteIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<palettes.count, id: \.self) { index in
                    let stops = palettes[index]

                    Button { onSelect(index) } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: stops.map { Color(
                                            red: Double($0.x),
                                            green: Double($0.y),
                                            blue: Double($0.z)
                                        ) },
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            index == activePaletteIndex
                                                ? Color.white
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )

                            Text(paletteNames[index])
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(
                                    index == activePaletteIndex
                                        ? .white
                                        : .white.opacity(0.5)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
