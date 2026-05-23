import SwiftUI

struct ReopenPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.74 : 1))
            }
            .contentShape(RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous))
    }
}

struct ReopenQuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? ReopenColor.quietFillHover : ReopenColor.quietFill)
            }
            .reopenSubtleBorder(opacity: 0.55)
            .contentShape(RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous))
    }
}

struct ReopenQuietIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: ReopenPanelMetrics.iconButtonSize, height: ReopenPanelMetrics.iconButtonSize)
            .background {
                RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? ReopenColor.quietFillHover : Color.clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: ReopenPanelMetrics.cornerRadius, style: .continuous))
    }
}

extension ButtonStyle where Self == ReopenPrimaryButtonStyle {
    static var reopenPrimary: ReopenPrimaryButtonStyle {
        ReopenPrimaryButtonStyle()
    }
}

extension ButtonStyle where Self == ReopenQuietButtonStyle {
    static var reopenQuiet: ReopenQuietButtonStyle {
        ReopenQuietButtonStyle()
    }
}

extension ButtonStyle where Self == ReopenQuietIconButtonStyle {
    static var reopenQuietIcon: ReopenQuietIconButtonStyle {
        ReopenQuietIconButtonStyle()
    }
}
