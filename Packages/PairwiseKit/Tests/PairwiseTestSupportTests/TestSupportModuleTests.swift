import Testing

@testable import PairwiseTestSupport

@Suite struct TestSupportModuleTests {
    @Test func namesItself() {
        #expect(TestSupportModule.name == "PairwiseTestSupport")
    }
}
