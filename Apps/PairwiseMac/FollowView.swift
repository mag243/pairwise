import PairwiseCore
import PairwiseUI
import SwiftUI

/// The spike's window: the permission, Start and Stop, and the last drag's numbers.
struct FollowView: View {
    private static let minimumWidth: CGFloat = 360
    private static let minimumHeight: CGFloat = 420
    private static let millisecondsPerSecond = 1000.0
    private static let fractionDigits = 1
    private static let lookAheadRange = 0...60
    private static let lookAheadStep = 4

    let model: FollowModel

    var body: some View {
        Form {
            controls
            Section("Last drag") {
                if let report = model.lastDrag {
                    measurements(of: report)
                } else {
                    Text("No drag measured yet.")
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            model.refreshPermission()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
        ) { _ in
            model.stop()
        }
    }

    @ViewBuilder private var controls: some View {
        Section {
            LabeledContent("Accessibility") {
                Text(model.isAccessibilityGranted ? "Granted" : "Not granted")
            }
            if !model.isAccessibilityGranted {
                Button("Grant Access…") { model.requestAccessibility() }
            }
            LabeledContent("Screen Recording") {
                Text(model.isScreenRecordingGranted ? "Granted" : "Not granted")
            }
            if !model.isScreenRecordingGranted {
                Button("Grant Screen Recording…") { model.requestScreenRecording() }
                Text("Without it, the Finder window itself follows, with some lag.")
                    .foregroundStyle(.secondary)
            }
            if model.isScreenRecordingGranted {
                Stepper(
                    value: lookAheadMilliseconds, in: Self.lookAheadRange, step: Self.lookAheadStep
                ) {
                    LabeledContent("Look ahead (ms)") {
                        Text(lookAheadMilliseconds.wrappedValue, format: .number).monospacedDigit()
                    }
                }
            }
            Button(model.isWatching ? "Stop" : "Start") {
                if model.isWatching { model.stop() } else { model.start() }
            }
            .disabled(!model.isAccessibilityGranted)
            Text("Drag any window by its title bar: a Finder window follows beside it.")
                .foregroundStyle(.secondary)
            if let problem = model.problem {
                Text(Self.text(for: problem)).foregroundStyle(.red)
            }
        }
    }

    private var lookAheadMilliseconds: Binding<Int> {
        Binding {
            Int((model.standInLookAhead * Self.millisecondsPerSecond).rounded())
        } set: { milliseconds in
            model.standInLookAhead = Double(milliseconds) / Self.millisecondsPerSecond
        }
    }

    @ViewBuilder private func measurements(of report: FollowReport) -> some View {
        LabeledContent("Moves") { Text(report.moves, format: .number) }
        row("Moves per second", report.movesPerSecond)
        row("Mean move (ms)", report.meanMove * Self.millisecondsPerSecond)
        row("95th percentile (ms)", report.percentile95Move * Self.millisecondsPerSecond)
        row("Longest move (ms)", report.longestMove * Self.millisecondsPerSecond)
        row("Mean points behind", report.meanPointsBehind)
        row("Most points behind", report.mostPointsBehind)
        if let delay = report.standInDelay {
            row("Stand-in appeared after (ms)", delay * Self.millisecondsPerSecond)
        } else {
            Text("No stand-in in this drag.")
        }
        if let slip = report.mostSlip {
            row("Off from the real window (points)", slip)
        }
    }

    private func row(_ label: LocalizedStringKey, _ value: Double) -> some View {
        LabeledContent(label) {
            Text(value, format: .number.precision(.fractionLength(Self.fractionDigits)))
                .monospacedDigit()
        }
    }

    private static func text(for problem: WindowSystemError) -> LocalizedStringKey {
        switch problem {
        case .accessibilityDenied: "Pairwise has no Accessibility access."
        case .eventTapUnavailable:
            "The pointer cannot be watched. Quit and reopen Pairwise after granting access."
        case .captureFailed: "No picture of the Finder window: it follows by itself."
        case .windowGone: "The window has gone."
        case .windowRefused: "The window refuses to move."
        case .windowBusy: "The window's app does not answer."
        case .noPartner: "No Finder window to follow: open one."
        }
    }
}
