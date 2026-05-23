import SwiftUI

enum ReopenPanelMetrics {
    static let width: CGFloat = 480
    static let height: CGFloat = 620
    static let cornerRadius: CGFloat = 8
    static let iconButtonSize: CGFloat = 28
    static let horizontalPadding: CGFloat = 18
    static let verticalPadding: CGFloat = 14
}

enum ReopenColor {
    static let hairline = Color(nsColor: .separatorColor).opacity(0.48)
    static let quietFill = Color.primary.opacity(0.055)
    static let quietFillHover = Color.primary.opacity(0.09)
    static let selectedFill = Color.accentColor.opacity(0.12)
    static let panelTint = Color(nsColor: .windowBackgroundColor).opacity(0.18)
}

struct ReopenPanelBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Rectangle()
                        .fill(.regularMaterial)
                    Rectangle()
                        .fill(ReopenColor.panelTint)
                }
            }
    }
}

struct ReopenSubtleBorder: ViewModifier {
    var cornerRadius: CGFloat = ReopenPanelMetrics.cornerRadius
    var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ReopenColor.hairline.opacity(opacity), lineWidth: 1)
            }
    }
}

extension View {
    func reopenPanelBackground() -> some View {
        modifier(ReopenPanelBackground())
    }

    func reopenSubtleBorder(
        cornerRadius: CGFloat = ReopenPanelMetrics.cornerRadius,
        opacity: Double = 1
    ) -> some View {
        modifier(ReopenSubtleBorder(cornerRadius: cornerRadius, opacity: opacity))
    }
}
