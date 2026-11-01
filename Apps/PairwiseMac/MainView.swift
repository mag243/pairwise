import PairwiseCore
import PairwiseUI
import SwiftUI

/// The app's window: the permissions, the partner app, Start and Stop, and the last drag's
/// numbers.
struct MainView: View {
    private static let minimumWidth: CGFloat = 360
    private static let minimumHeight: CGFloat = 420
    private static let millisecondsPerSecond = 1000.0
    private static let fractionDigits = 1

    let model: PairDragModel

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
            model.refreshPermissions()
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
                Text("Without it, windows move one at a time.")
                    .foregroundStyle(.secondary)
            }
            Picker("Partner app", selection: partnerApp) {
                ForEach(model.partnerApps) { app in
                    Text(verbatim: app.name).tag(app.bundleIdentifier)
                }
            }
            Button(model.isRunning ? "Stop" : "Start") {
                if model.isRunning { model.stop() } else { model.start() }
            }
            .disabled(!model.isAccessibilityGranted || !model.isScreenRecordingGranted)
            Text("Drag a window by its title bar: it and the partner move as one.")
                .foregroundStyle(.secondary)
            if let problem = model.problem {
                Text(problem.message).foregroundStyle(.red)
            }
        }
    }

    private var partnerApp: Binding<String> {
        Binding {
            model.partnerBundleIdentifier
        } set: {
            model.partnerBundleIdentifier = $0
        }
    }

    @ViewBuilder private func measurements(of report: DragReport) -> some View {
        LabeledContent("Moves") { Text(report.moves, format: .number) }
        row("Moves per second", report.movesPerSecond)
        row("Mean move (ms)", report.meanMove * Self.millisecondsPerSecond)
        row("95th percentile (ms)", report.percentile95Move * Self.millisecondsPerSecond)
        row("Longest move (ms)", report.longestMove * Self.millisecondsPerSecond)
        row("Panel appeared after (ms)", report.panelDelay * Self.millisecondsPerSecond)
    }

    private func row(_ label: LocalizedStringKey, _ value: Double) -> some View {
        LabeledContent(label) {
            Text(value, format: .number.precision(.fractionLength(Self.fractionDigits)))
                .monospacedDigit()
        }
    }
}
