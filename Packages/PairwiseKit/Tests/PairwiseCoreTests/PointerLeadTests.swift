import PairwiseCore
import Testing

@Suite struct PointerLeadTests {
    private static let place = ScreenPoint(x: 100, y: 100)

    private func point(_ x: Double, _ y: Double = 0) -> ScreenPoint {
        ScreenPoint(x: x, y: y)
    }

    @Test func aFirstNoteAddsNothing() {
        var lead = PointerLead()
        let result = lead.ahead(of: Self.place, pointer: point(10), at: 0, lookingAhead: 0.016)
        #expect(result == Self.place)
    }

    @Test func aMovingPointerAddsHowFarItWentInThatTime() {
        var lead = PointerLead()
        _ = lead.ahead(of: Self.place, pointer: point(10), at: 0, lookingAhead: 0.016)
        _ = lead.ahead(of: Self.place, pointer: point(20), at: 0.01, lookingAhead: 0.016)
        let result = lead.ahead(of: Self.place, pointer: point(30), at: 0.02, lookingAhead: 0.016)
        #expect(result == ScreenPoint(x: 120, y: 100))
    }

    @Test func movementOlderThanTheTimeDoesNotCount() {
        var lead = PointerLead()
        _ = lead.ahead(of: Self.place, pointer: point(10), at: 0, lookingAhead: 0.016)
        _ = lead.ahead(of: Self.place, pointer: point(20), at: 0.01, lookingAhead: 0.016)
        let result = lead.ahead(of: Self.place, pointer: point(30), at: 0.03, lookingAhead: 0.016)
        #expect(result == ScreenPoint(x: 110, y: 100))
    }

    @Test func aPointerAtRestAddsNothing() {
        var lead = PointerLead()
        _ = lead.ahead(of: Self.place, pointer: point(10), at: 0, lookingAhead: 0.016)
        _ = lead.ahead(of: Self.place, pointer: point(20), at: 0.01, lookingAhead: 0.016)
        let result = lead.ahead(of: Self.place, pointer: point(20), at: 0.5, lookingAhead: 0.016)
        #expect(result == Self.place)
    }

    @Test func movementCountsInBothDirections() {
        var lead = PointerLead()
        _ = lead.ahead(of: Self.place, pointer: point(30, 5), at: 0, lookingAhead: 0.016)
        let result = lead.ahead(
            of: Self.place, pointer: point(10, 15), at: 0.02, lookingAhead: 0.016)
        #expect(result == ScreenPoint(x: 80, y: 110))
    }

    @Test func noTimeAddsNothing() {
        var lead = PointerLead()
        _ = lead.ahead(of: Self.place, pointer: point(10), at: 0, lookingAhead: 0)
        let result = lead.ahead(of: Self.place, pointer: point(20), at: 0.01, lookingAhead: 0)
        #expect(result == Self.place)
    }
}
