import SwiftUI

struct PermissionOnboardingView: View {
    let kinds: [PermissionKind]
    let onOpenSettings: (PermissionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(kinds, id: \.self) { kind in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconName(for: kind))
                        .frame(width: 22)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind.title)
                            .fontWeight(.semibold)
                        Text(kind.explanation)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if kind.settingsURL != nil {
                        Button("Open Settings") {
                            onOpenSettings(kind)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func iconName(for kind: PermissionKind) -> String {
        switch kind {
        case .accessibility:
            return "rectangle.and.hand.point.up.left"
        case .automation:
            return "terminal"
        case .fileAccess:
            return "folder"
        }
    }
}
