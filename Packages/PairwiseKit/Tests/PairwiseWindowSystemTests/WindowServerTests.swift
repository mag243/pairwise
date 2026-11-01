import CoreGraphics
import Foundation
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@Suite struct WindowServerTests {
    @Test func aDescriptionGivesItsFrame() {
        let rect = CGRect(x: 10, y: 20, width: 300, height: 200)
        let description: [String: Any] = [
            kCGWindowBounds as String: rect.dictionaryRepresentation
        ]
        #expect(
            WindowServer.frame(from: description)
                == WindowFrame(x: 10, y: 20, width: 300, height: 200))
    }

    @Test func aDescriptionWithoutBoundsGivesNoFrame() {
        #expect(WindowServer.frame(from: [:]) == nil)
    }
}
