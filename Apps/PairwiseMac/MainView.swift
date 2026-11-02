import PairwiseCore
import PairwiseUI
import SwiftUI

/// The settings window: the permissions, the choices for joining, and how Pairwise works.
struct MainView: View {
    private static let width: CGFloat = 480
    private static let height: CGFloat = 420
    #if DEBUG
    private static let millisecondsPerSecond = 1000.0
    private static let fractionDigits = 1
    private static let frameRates = [15, 30, 60]
    #endif
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

    @State private var tab = Self.firstTab

    /// The first tab, or in a debug build one asked for, to look at each tab in a test.
    private static var firstTab: Int {
        #if DEBUG
        let arguments = CommandLine.arguments
        if let flag = arguments.firstIndex(of: "--settings-tab"),
            arguments.indices.contains(flag + 1), let tab = Int(arguments[flag + 1])
        {
            return tab
        }
        #endif
        return 0
    }

    /// One tab: a form in the app's usual style, which scrolls if its content needs that.
    private func page<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        Form { content() }.formStyle(.grouped)
    }

    var body: some View {
        TabView(selection: $tab) {
            page {
                permissions
                joining
                if let problem = model.problem {
                    Text(problem.message).foregroundStyle(.red)
                }
            }
            .tabItem { Label("General", systemImage: "gearshape") }
            .tag(0)
            page { howItWorks }
                .tabItem { Label("How it works", systemImage: "questionmark.circle") }
                .tag(1)
            #if DEBUG
            page { testing }
                .tabItem { Label("For testing", systemImage: "hammer") }
                .tag(2)
            #endif
        }
        .frame(width: Self.width, height: Self.height)
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

    @ViewBuilder private var permissions: some View {
        Section("Permissions") {
            LabeledContent {
                Text(model.isAccessibilityGranted ? "Granted" : "Not granted")
            } label: {
                Text("Accessibility")
                Text("Lets Pairwise move and resize the windows you join.")
            }
            if !model.isAccessibilityGranted {
                Button("Grant Access…") { model.requestAccessibility() }
            }
            LabeledContent {
                Text(model.isScreenRecordingGranted ? "Granted" : "Not granted")
            } label: {
                Text("Screen Recording")
                Text(
                    "Lets Pairwise show pictures of joined windows while you drag them. They are not saved or sent anywhere."
                )
            }
            if !model.isScreenRecordingGranted {
                Button("Grant Screen Recording…") { model.requestScreenRecording() }
            }
            if !model.isAccessibilityGranted || !model.isScreenRecordingGranted {
                Text("Pairwise needs both to work.").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var joining: some View {
        Section("Joining") {
            Picker("Command joins with", selection: joinScope) {
                Text("Any window").tag(JoinScope.anyWindow)
                Text("Windows of the same app").tag(JoinScope.sameApp)
            }
            Toggle("Sound when windows join or part", isOn: playsSounds)
        }
    }

    @ViewBuilder private var howItWorks: some View {
        Section("How it works") {
            Group {
                Text(
                    "To join, drag a window to another and press Command, or click the open lock on the seam of two windows side by side."
                )
                Text(
                    "While joining, add Shift for the same height, or Control for the other choice of windows."
                )
                Text("To move a pair, drag either window.")
                Text("To resize both, drag the seam between them.")
                Text(
                    "To part them, click the closed lock on the seam, or press Command while dragging one."
                )
            }
            .foregroundStyle(.secondary)
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

    #if DEBUG
    /// What only a test of the app itself needs (ADR 0050).
    @ViewBuilder private var testing: some View {
        Section("For testing") {
            Picker("Live pictures", selection: liveFrames) {
                Text("Still").tag(0)
                ForEach(Self.frameRates, id: \.self) { rate in
                    Text("\(rate) frames a second").tag(rate)
                }
            }
            if let report = model.lastDrag {
                measurements(of: report)
            } else {
                Text("No drag measured yet.")
            }
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
    #endif
}
