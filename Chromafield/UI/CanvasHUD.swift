import SwiftUI

struct CanvasHUD: View {
    let nodeCount: Int
    let particleCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(nodeCount) nodes · \(formatCount(particleCount)) particles")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.4))
                .clipShape(Capsule())
        }
    }

    private func formatCount(_ n: Int) -> String {
        n >= 1000 ? "\(n / 1000)K" : "\(n)"
    }
}
