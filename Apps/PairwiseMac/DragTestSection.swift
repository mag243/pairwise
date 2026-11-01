import PairwiseCore
import PairwiseUI
import SwiftUI

/// The test of whether a window drag can be held back (ADR 0023).
struct DragTestSection: View {
    private static let fractionDigits = 1

    let test: DragHoldTest
    let isFollowing: Bool

    var body: some View {
        Section("Drag test") {
            Button(test.isRunning ? "Stop test" : "Start test") {
                if test.isRunning { test.stop() } else { test.start() }
            }
            .disabled(isFollowing)
            Text(
                "While the test runs, title bars of other apps' windows should not drag. Clicks should still work."
            )
            .foregroundStyle(.secondary)
            if test.problem != nil {
                Text(
                    "The pointer cannot be watched. Quit and reopen Pairwise after granting access."
                )
                .foregroundStyle(.red)
            }
            if let report = test.lastReport {
                row("Pointer moved (points)", report.pointerTravel)
                row("Window moved (points)", report.windowTravel)
                LabeledContent("Drags held back") { Text(report.heldEvents, format: .number) }
            }
        }
    }

    private func row(_ label: LocalizedStringKey, _ value: Double) -> some View {
        LabeledContent(label) {
            Text(value, format: .number.precision(.fractionLength(Self.fractionDigits)))
                .monospacedDigit()
        }
    }
}
