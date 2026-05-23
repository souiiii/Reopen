import AppKit
import Foundation

struct WindowScreen: Equatable, Sendable {
    var identifier: String
    var visibleFrame: WindowFrame

    init(identifier: String, visibleFrame: WindowFrame) {
        self.identifier = identifier
        self.visibleFrame = visibleFrame
    }
}

final class WindowLayoutCalculator {
    func targetFrame(for layout: WindowLayout, screens: [WindowScreen]) -> WindowFrame {
        let screen = bestScreen(for: layout, screens: screens)
        let visibleFrame = screen.visibleFrame

        switch layout.placement {
        case .leftHalf:
            return WindowFrame(
                x: visibleFrame.x,
                y: visibleFrame.y,
                width: visibleFrame.width / 2,
                height: visibleFrame.height
            )
        case .rightHalf:
            return WindowFrame(
                x: visibleFrame.x + visibleFrame.width / 2,
                y: visibleFrame.y,
                width: visibleFrame.width / 2,
                height: visibleFrame.height
            )
        case .topHalf:
            return WindowFrame(
                x: visibleFrame.x,
                y: visibleFrame.y + visibleFrame.height / 2,
                width: visibleFrame.width,
                height: visibleFrame.height / 2
            )
        case .bottomHalf:
            return WindowFrame(
                x: visibleFrame.x,
                y: visibleFrame.y,
                width: visibleFrame.width,
                height: visibleFrame.height / 2
            )
        case .center:
            let width = min(layout.width, visibleFrame.width * 0.72)
            let height = min(layout.height, visibleFrame.height * 0.72)
            return WindowFrame(
                x: visibleFrame.x + (visibleFrame.width - width) / 2,
                y: visibleFrame.y + (visibleFrame.height - height) / 2,
                width: width,
                height: height
            )
        case .fullscreen:
            return visibleFrame
        case .customRectangle:
            return bestEffortClampedFrame(
                WindowFrame(x: layout.x, y: layout.y, width: layout.width, height: layout.height),
                to: visibleFrame
            )
        }
    }

    static func currentScreens() -> [WindowScreen] {
        NSScreen.screens.map { screen in
            WindowScreen(
                identifier: screen.localizedName,
                visibleFrame: WindowFrame(screen.visibleFrame)
            )
        }
    }

    private func bestScreen(for layout: WindowLayout, screens: [WindowScreen]) -> WindowScreen {
        let fallback = screens.first ?? WindowScreen(
            identifier: "main",
            visibleFrame: WindowFrame(x: 0, y: 0, width: 1440, height: 900)
        )

        if let screenIdentifier = layout.screenIdentifier,
           let matchingScreen = screens.first(where: { $0.identifier == screenIdentifier }) {
            return matchingScreen
        }

        let centerX = layout.x + layout.width / 2
        let centerY = layout.y + layout.height / 2

        return screens.first { screen in
            let frame = screen.visibleFrame
            return centerX >= frame.x
                && centerX <= frame.x + frame.width
                && centerY >= frame.y
                && centerY <= frame.y + frame.height
        } ?? fallback
    }

    private func bestEffortClampedFrame(_ frame: WindowFrame, to screen: WindowFrame) -> WindowFrame {
        let width = min(max(frame.width, 120), screen.width)
        let height = min(max(frame.height, 120), screen.height)
        let x = min(max(frame.x, screen.x), screen.x + screen.width - width)
        let y = min(max(frame.y, screen.y), screen.y + screen.height - height)

        return WindowFrame(x: x, y: y, width: width, height: height)
    }
}
