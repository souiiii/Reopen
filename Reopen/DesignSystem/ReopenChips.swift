import SwiftUI

struct ReopenChipStyle: ViewModifier {
    var isEmphasized = false

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(isEmphasized ? .semibold : .medium)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(isEmphasized ? Color.accentColor.opacity(0.16) : ReopenColor.quietFill)
            }
            .overlay {
                Capsule()
                    .stroke(ReopenColor.hairline.opacity(0.75), lineWidth: 1)
            }
    }
}

struct ReopenChip: View {
    var title: String
    var systemImage: String?
    var isEmphasized = false

    var body: some View {
        Label {
            Text(title)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .labelStyle(.titleAndIcon)
        .reopenChip(isEmphasized: isEmphasized)
    }
}

extension View {
    func reopenChip(isEmphasized: Bool = false) -> some View {
        modifier(ReopenChipStyle(isEmphasized: isEmphasized))
    }
}
