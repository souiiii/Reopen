import Foundation

enum ModelCheckFailure: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw ModelCheckFailure.message(message)
    }
}

@main
enum WorkspaceModelChecks {
    static func main() throws {
        try workspaceRoundTripsThroughJSON()
        try invalidActionTypeThrowsDecodingError()
        try oldWorkspaceJSONWithKnownActionTypeDecodes()
        try actionTypeRawValuesMatchImplementationPlan()

        print("Workspace model checks passed.")
    }

    private static func workspaceRoundTripsThroughJSON() throws {
        let workspace = Workspace(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Coding",
            icon: "code",
            color: "blue",
            description: "Opens the development setup",
            actions: [
                .openApp(OpenAppAction(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    name: "Visual Studio Code",
                    path: "/Applications/Visual Studio Code.app",
                    bundleIdentifier: "com.microsoft.VSCode"
                )),
                .openFile(OpenFileAction(
                    id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                    name: "Brief",
                    path: "/Users/me/Documents/brief.pdf"
                )),
                .openFolder(OpenFolderAction(
                    id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                    name: "Project",
                    path: "/Users/me/Projects/App"
                )),
                .openURL(OpenURLAction(
                    id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                    url: "https://github.com/example/project",
                    displayTitle: "GitHub"
                )),
                .terminalCommand(TerminalCommandAction(
                    id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                    name: "Dev Server",
                    command: "npm run dev",
                    workingDirectory: "/Users/me/Projects/App"
                )),
                .openVSCodeProject(OpenVSCodeProjectAction(
                    id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
                    projectPath: "/Users/me/Projects/App"
                )),
                .shellScript(ShellScriptAction(
                    id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
                    name: "Bootstrap",
                    scriptPath: "/Users/me/Projects/App/scripts/bootstrap.sh",
                    workingDirectory: "/Users/me/Projects/App"
                ))
            ],
            windowLayouts: [
                WindowLayout(
                    id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                    appBundleIdentifier: "com.microsoft.VSCode",
                    windowTitle: "App",
                    screenIdentifier: "main",
                    x: 0,
                    y: 0,
                    width: 720,
                    height: 900
                )
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 100),
            updatedAt: Date(timeIntervalSinceReferenceDate: 200)
        )

        let data = try JSONEncoder().encode(workspace)
        let decoded = try JSONDecoder().decode(Workspace.self, from: data)

        try check(decoded == workspace, "Workspace JSON round trip did not preserve the model.")

        guard let json = String(data: data, encoding: .utf8) else {
            throw ModelCheckFailure.message("Could not convert encoded workspace JSON to UTF-8 text.")
        }

        try check(json.contains(#""type":"openApp""#), "Encoded JSON is missing openApp action type.")
        try check(json.contains(#""type":"terminalCommand""#), "Encoded JSON is missing terminalCommand action type.")
        try check(json.contains(#""type":"shellScript""#), "Encoded JSON is missing shellScript action type.")
    }

    private static func invalidActionTypeThrowsDecodingError() throws {
        let json = """
        {
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "name": "Broken",
          "actions": [
            {
              "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
              "type": "openDatabase"
            }
          ],
          "windowLayouts": [],
          "createdAt": 0,
          "updatedAt": 0
        }
        """

        do {
            _ = try JSONDecoder().decode(Workspace.self, from: Data(json.utf8))
            throw ModelCheckFailure.message("Expected a safe dataCorrupted decoding error.")
        } catch DecodingError.dataCorrupted {
        } catch {
            throw ModelCheckFailure.message("Expected dataCorrupted, got \(error).")
        }
    }

    private static func oldWorkspaceJSONWithKnownActionTypeDecodes() throws {
        let json = """
        {
          "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          "name": "Research",
          "actions": [
            {
              "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
              "type": "openURL",
              "url": "https://example.com"
            }
          ],
          "windowLayouts": [],
          "createdAt": 0,
          "updatedAt": 0
        }
        """

        let workspace = try JSONDecoder().decode(Workspace.self, from: Data(json.utf8))

        try check(workspace.name == "Research", "Decoded workspace name was not preserved.")
        try check(workspace.actions.count == 1, "Decoded workspace should contain exactly one action.")
        try check(workspace.actions.first?.type == .openURL, "Decoded action type should be openURL.")
    }

    private static func actionTypeRawValuesMatchImplementationPlan() throws {
        let expectedRawValues = [
            "openApp",
            "openFile",
            "openFolder",
            "openURL",
            "terminalCommand",
            "openVSCodeProject",
            "shellScript"
        ]

        try check(
            WorkspaceActionType.allCases.map(\.rawValue) == expectedRawValues,
            "Workspace action type raw values drifted from the implementation plan."
        )
    }
}
