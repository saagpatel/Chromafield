import SwiftUI

struct BehaviorPicker: View {
    let currentBehavior: ParticleBehavior
    let onSelect: (ParticleBehavior) -> Void

    private let items: [(ParticleBehavior, String)] = [
        (.flocking, "bird"),
        (.diffusion, "sparkles"),
        (.crystallization, "hexagon"),
        (.orbital, "circle.dashed"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Behavior")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)

            ForEach(items, id: \.0) { behavior, iconName in
                Button { onSelect(behavior) } label: {
                    HStack(spacing: 16) {
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(behavior.displayName)
                                .font(.system(size: 16, weight: .bold))
                            Text(behavior.description)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        Spacer()

                        if behavior == currentBehavior {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.cyan)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        behavior == currentBehavior
                            ? Color.white.opacity(0.1)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.white)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.95))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
