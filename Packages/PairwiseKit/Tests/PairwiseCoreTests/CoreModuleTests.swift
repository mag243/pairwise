import Testing

@testable import PairwiseCore

@Suite struct CoreModuleTests {
    @Test func namesItself() {
        #expect(CoreModule.name == "PairwiseCore")
    }
}
