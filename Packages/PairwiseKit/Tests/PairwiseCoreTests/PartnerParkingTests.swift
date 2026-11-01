import PairwiseCore
import Testing

@Suite struct PartnerParkingTests {
    @Test func noDisplaysLeaveNoPlace() {
        #expect(PartnerPlacement.parkingOrigin(onDisplays: []) == nil)
    }

    @Test func oneDisplayParksInItsBottomRightCorner() {
        let display = WindowFrame(x: 0, y: 0, width: 1440, height: 900)
        #expect(
            PartnerPlacement.parkingOrigin(onDisplays: [display])
                == ScreenPoint(x: 1439, y: 899))
    }

    @Test func severalDisplaysParkPastAllOfThem() {
        let main = WindowFrame(x: 0, y: 0, width: 1440, height: 900)
        let right = WindowFrame(x: 1440, y: -200, width: 1920, height: 1080)
        let below = WindowFrame(x: 0, y: 900, width: 1000, height: 600)
        #expect(
            PartnerPlacement.parkingOrigin(onDisplays: [main, right, below])
                == ScreenPoint(x: 3359, y: 1499))
    }
}
