import ApplicationServices
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@Suite struct AXErrorMappingTests {
    @Test(arguments: [
        (AXError.invalidUIElement, WindowSystemError.windowGone),
        (.apiDisabled, .accessibilityDenied),
        (.cannotComplete, .windowBusy),
        (.attributeUnsupported, .windowRefused),
        (.failure, .windowRefused),
    ])
    func aFailedCallMapsToAReason(error: AXError, reason: WindowSystemError) {
        #expect(WindowSystemError(error) == reason)
    }
}
