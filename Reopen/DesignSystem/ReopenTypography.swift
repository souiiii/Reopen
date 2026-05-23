import SwiftUI

struct ReopenPanelTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .fontWeight(.semibold)
            .lineLimit(1)
    }
}

struct ReopenSectionTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

struct ReopenBodySecondaryStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    func reopenPanelTitle() -> some View {
        modifier(ReopenPanelTitleStyle())
    }

    func reopenSectionTitle() -> some View {
        modifier(ReopenSectionTitleStyle())
    }

    func reopenBodySecondary() -> some View {
        modifier(ReopenBodySecondaryStyle())
    }
}
