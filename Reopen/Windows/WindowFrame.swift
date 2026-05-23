import CoreGraphics
import Foundation

struct WindowFrame: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(_ rect: CGRect) {
        self.init(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )
    }

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    var centerX: Double {
        x + width / 2
    }

    var centerY: Double {
        y + height / 2
    }
}
