import SwiftUI

struct ReopenCardStyle: ViewModifier {
    var isSelected = false
    var isHovered = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                    .fill(backgroundStyle)
            }
            .reopenSubtleBorder(opacity: isSelected || isHovered ? 0.9 : 0.65)
            .shadow(color: .black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 10 : 5, y: 2)
    }

    private var backgroundStyle: Color {
        if isSelected {
            return ReopenColor.selectedFill
        }

        if isHovered {
            return ReopenColor.quietFillHover
        }

        return ReopenColor.quietFill
    }
}

struct ReopenHoverStyle: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                    .fill(isHovered ? ReopenColor.quietFillHover : Color.clear)
            }
            .onHover { isHovered = $0 }
    }
}

struct ReopenEmptyStateStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
    }
}

extension View {
    func reopenCard(isSelected: Bool = false, isHovered: Bool = false) -> some View {
        modifier(ReopenCardStyle(isSelected: isSelected, isHovered: isHovered))
    }

    func reopenHoverStyle() -> some View {
        modifier(ReopenHoverStyle())
    }

    func reopenEmptyStateStyle() -> some View {
        modifier(ReopenEmptyStateStyle())
    }
}
