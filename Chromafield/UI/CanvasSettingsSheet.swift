import SwiftUI

struct CanvasSettingsSheet: View {
    let particleCount: Int
    let maxParticles: Int
    let currentBehavior: ParticleBehavior
    let onSelectBehavior: (ParticleBehavior) -> Void
    let onClearNodes: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Canvas")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)

            // Particle count
            HStack {
                Image(systemName: "sparkle")
                    .font(.system(size: 18))
                    .foregroundStyle(.cyan)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Particles")
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(formatCount(particleCount)) of \(formatCount(maxParticles)) max")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            // Behavior selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Behavior")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ParticleBehavior.allCases, id: \.self) { behavior in
                            Button { onSelectBehavior(behavior) } label: {
                                Text(behavior.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        behavior == currentBehavior
                                            ? Color.cyan.opacity(0.3)
                                            : Color.white.opacity(0.1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .foregroundStyle(
                                behavior == currentBehavior ? .cyan : .white.opacity(0.7)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Divider()
                .background(.white.opacity(0.2))
                .padding(.horizontal, 20)

            // Clear all nodes
            Button(role: .destructive, action: onClearNodes) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear All Nodes")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.red.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .foregroundStyle(.red)
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.95))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func formatCount(_ n: Int) -> String {
        n >= 1000 ? "\(n / 1000)K" : "\(n)"
    }
}
