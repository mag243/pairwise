import PairwiseCore
import PairwiseUI
import SwiftUI

/// The settings window: the permissions, Start and Stop, and the last drag's numbers.
struct MainView: View {
    private static let minimumWidth: CGFloat = 360
    private static let minimumHeight: CGFloat = 420
    private static let millisecondsPerSecond = 1000.0
    private static let fractionDigits = 1
    private static let frameRates = [15, 30, 60]
    private static let joinScopeKey = "joinScope"
    private static let playsSoundsKey = "playsSounds"

    /// Whether a join and a parting make a sound, as stored the last time; on until turned off.
    static var storedPlaysSounds: Bool {
        UserDefaults.standard.object(forKey: playsSoundsKey) as? Bool ?? true
    }

    /// The choice of which windows Command joins, as stored the last time.
    static var storedJoinScope: JoinScope {
        UserDefaults.standard.string(forKey: joinScopeKey).flatMap(JoinScope.init(rawValue:))
            ?? .anyWindow
    }

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
            Picker("Command joins with", selection: joinScope) {
                Text("Any window").tag(JoinScope.anyWindow)
                Text("Windows of the same app").tag(JoinScope.sameApp)
            }
            Toggle("Sound when windows join or part", isOn: playsSounds)
            Picker("Live pictures", selection: liveFrames) {
                Text("Still").tag(0)
                ForEach(Self.frameRates, id: \.self) { rate in
                    Text("\(rate) frames a second").tag(rate)
                }
            }
            Button(model.isRunning ? "Stop" : "Start") {
                if model.isRunning { model.stop() } else { model.start() }
            }
            .disabled(!model.isAccessibilityGranted || !model.isScreenRecordingGranted)
            Text(
                "Drag a window and hold Command over another window to join them; add Shift to give it the same height, or Control for the other choice of windows. A lock also shows on the seam of windows side by side: click it to join or part them. Holding Command while dragging a joined window parts it too."
            )
            .foregroundStyle(.secondary)
            if let problem = model.problem {
                Text(problem.message).foregroundStyle(.red)
            }
        }
    }

    private var joinScope: Binding<JoinScope> {
        Binding {
            model.joinScope
        } set: {
            model.joinScope = $0
            UserDefaults.standard.set($0.rawValue, forKey: Self.joinScopeKey)
        }
    }

    private var playsSounds: Binding<Bool> {
        Binding {
            model.playsSounds
        } set: {
            model.playsSounds = $0
            UserDefaults.standard.set($0, forKey: Self.playsSoundsKey)
        }
    }

    private var liveFrames: Binding<Int> {
        Binding {
            model.liveFramesPerSecond
        } set: {
            model.liveFramesPerSecond = $0
        }
    }

    @ViewBuilder private func measurements(of report: DragReport) -> some View {
        LabeledContent("Moves") { Text(report.moves, format: .number) }
        row("Moves per second", report.movesPerSecond)
        row("Mean move (ms)", report.meanMove * Self.millisecondsPerSecond)
        row("95th percentile (ms)", report.percentile95Move * Self.millisecondsPerSecond)
        row("Longest move (ms)", report.longestMove * Self.millisecondsPerSecond)
        row("Panel appeared after (ms)", report.panelDelay * Self.millisecondsPerSecond)
        ForEach(Array(report.liveFrames.enumerated()), id: \.offset) { index, frames in
            LabeledContent("Live frames, window \(index + 1)") {
                Text(frames, format: .number)
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
