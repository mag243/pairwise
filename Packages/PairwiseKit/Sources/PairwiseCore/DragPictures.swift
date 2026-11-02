/// What the pictures of a pair show during a drag, the user's choice (ADR 0063).
public enum DragPictures: String, CaseIterable, Sendable {
    /// An empty plane with the window's title for each window, for which nothing is captured.
    case placeholder
    /// One picture of each window at the start of a drag.
    case still
    /// The windows' live frames, for which macOS shows its recording icon.
    case live

    /// What a user who has not chosen gets.
    public static let standard = DragPictures.placeholder

    /// How often the pictures update; 0 means that no stream runs.
    public var framesPerSecond: Int {
        switch self {
        case .placeholder, .still: 0
        case .live: Self.liveFramesPerSecond
        }
    }

    private static let liveFramesPerSecond = 30

    /// Whether this choice captures windows, which takes the Screen Recording permission.
    public var needsScreenRecording: Bool { self != .placeholder }
}
