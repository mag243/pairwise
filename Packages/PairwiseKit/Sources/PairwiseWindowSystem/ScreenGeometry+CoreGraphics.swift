import CoreGraphics
import PairwiseCore

extension ScreenPoint {
    init(_ point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y))
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

extension WindowFrame {
    init(origin: CGPoint, size: CGSize) {
        self.init(
            x: Double(origin.x), y: Double(origin.y),
            width: Double(size.width), height: Double(size.height))
    }
}
