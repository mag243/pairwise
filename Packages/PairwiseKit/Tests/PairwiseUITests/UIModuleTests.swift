import Testing

@testable import PairwiseUI

@Suite struct UIModuleTests {
    @Test func namesItself() {
        #expect(UIModule.name == "PairwiseUI")
    }
}
