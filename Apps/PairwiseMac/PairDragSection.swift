import PairwiseCore
import PairwiseUI
import SwiftUI

/// Moving a window and its partner as one window of Pairwise's own (ADR 0024).
struct PairDragSection: View {
    private static let millisecondsPerSecond = 1000.0
    private static let fractionDigits = 1

    let model: PairDragModel
    let isFollowing: Bool

    var body: some View {
        Section("Move as one") {
            Button(model.isRunning ? "Stop moving as one" : "Start moving as one") {
                if model.isRunning { model.stop() } else { model.start() }
            }
            .disabled(isFollowing)
            Text("Drag a window by its title bar: it and the partner move as one picture.")
                .foregroundStyle(.secondary)
            if let problem = model.problem {
                Text(problem.message).foregroundStyle(.red)
            }
            if let report = model.lastDrag {
                LabeledContent("Moves") { Text(report.moves, format: .number) }
                row("Moves per second", report.movesPerSecond)
                row("Mean move (ms)", report.meanMove * Self.millisecondsPerSecond)
                row("Longest move (ms)", report.longestMove * Self.millisecondsPerSecond)
                if let delay = report.standInDelay {
                    row("Stand-in appeared after (ms)", delay * Self.millisecondsPerSecond)
                }
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
