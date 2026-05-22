import Foundation

struct TerminalCommandSafety {
    struct Assessment: Equatable {
        var isDangerous: Bool
        var reason: String?
    }

    func assess(_ command: String) -> Assessment {
        let normalized = command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let dangerousPatterns: [(pattern: String, reason: String)] = [
            ("rm -rf", "recursive deletion"),
            ("sudo rm", "privileged deletion"),
            ("diskutil erase", "disk erase"),
            ("mkfs", "filesystem formatting"),
            ("dd if=", "raw disk write"),
            ("shutdown", "system shutdown"),
            ("reboot", "system restart"),
            ("killall", "process termination"),
            ("pkill", "process termination"),
            ("chmod -r 777", "broad permission change"),
            ("chown -r", "broad ownership change"),
            ("curl ", "downloaded script risk"),
            ("wget ", "downloaded script risk"),
            (":(){", "fork bomb pattern")
        ]

        for item in dangerousPatterns where normalized.contains(item.pattern) {
            if item.pattern == "curl " || item.pattern == "wget " {
                guard normalized.contains("| sh") || normalized.contains("| bash") else {
                    continue
                }
            }

            return Assessment(isDangerous: true, reason: item.reason)
        }

        return Assessment(isDangerous: false, reason: nil)
    }

    func requiresConfirmation(for action: TerminalCommandAction) -> Bool {
        action.requiresConfirmation || assess(action.command).isDangerous
    }
}
