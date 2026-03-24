import SwiftUI

struct RadialNodeMenu: View {
    let position: CGPoint
    let onSelect: (FieldNodeModel.FieldNodeType) -> Void
    let onDismiss: () -> Void

    @State private var isAppearing = false

    private let radius: CGFloat = 70
    private let buttonSize: CGFloat = 56
    private let types: [(FieldNodeModel.FieldNodeType, Angle)] = [
        (.attractor,  .degrees(270)),  // top
        (.repeller,   .degrees(0)),    // right
        (.vortex,     .degrees(90)),   // bottom
        (.turbulence, .degrees(180)),  // left
    ]

    var body: some View {
        GeometryReader { proxy in
            let clamped = clampedPosition(in: proxy.size)

            ZStack {
                // Tap-outside dismiss area
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { onDismiss() }

                // Dark backdrop circle
                Circle()
                    .fill(.black.opacity(0.4))
                    .frame(width: radius * 2 + buttonSize, height: radius * 2 + buttonSize)
                    .position(clamped)

                // Node type buttons
                ForEach(types, id: \.0) { (type, angle) in
                    let offset = CGPoint(
                        x: cos(angle.radians) * radius,
                        y: sin(angle.radians) * radius
                    )

                    Button {
                        onSelect(type)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type.systemImage)
                                .font(.system(size: 22, weight: .medium))
                            Text(type.displayName)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.15))
                        .clipShape(Circle())
                    }
                    .position(
                        x: clamped.x + offset.x,
                        y: clamped.y + offset.y
                    )
                }
            }
            .scaleEffect(isAppearing ? 1.0 : 0.3)
            .opacity(isAppearing ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAppearing)
            .onAppear { isAppearing = true }
        }
        .ignoresSafeArea()
    }

    private func clampedPosition(in size: CGSize) -> CGPoint {
        let margin = radius + buttonSize / 2 + 8
        return CGPoint(
            x: min(max(position.x, margin), size.width - margin),
            y: min(max(position.y, margin), size.height - margin)
        )
    }
}
