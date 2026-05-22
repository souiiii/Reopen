import SwiftUI

struct IconPicker: View {
    @Binding var selection: String?

    private let icons = [
        "curlybraces",
        "pencil",
        "paintbrush",
        "briefcase",
        "book",
        "video",
        "folder"
    ]

    var body: some View {
        Picker("Icon", selection: Binding(
            get: { selection ?? "" },
            set: { selection = $0.isEmpty ? nil : $0 }
        )) {
            Label("None", systemImage: "circle").tag("")
            ForEach(icons, id: \.self) { icon in
                Label(icon, systemImage: icon).tag(icon)
            }
        }
        .labelsHidden()
    }
}

struct WorkspaceColorPicker: View {
    @Binding var selection: String?

    private let colors: [(name: String, value: String?, color: Color)] = [
        ("None", nil, Color(nsColor: .separatorColor)),
        ("Blue", "blue", .blue),
        ("Green", "green", .green),
        ("Yellow", "yellow", .yellow),
        ("Pink", "pink", .pink),
        ("Gray", "gray", .gray)
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(colors, id: \.name) { colorOption in
                Button {
                    selection = colorOption.value
                } label: {
                    Circle()
                        .fill(colorOption.color)
                        .frame(width: 18, height: 18)
                        .overlay {
                            if selection == colorOption.value {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .help(colorOption.name)
            }
        }
    }
}
