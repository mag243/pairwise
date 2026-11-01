import Testing

@testable import PairwiseWindowSystem

@Suite struct WindowSystemModuleTests {
    @Test func namesItself() {
        #expect(WindowSystemModule.name == "PairwiseWindowSystem")
    }
}
