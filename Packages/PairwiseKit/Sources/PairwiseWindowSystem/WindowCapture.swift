import PairwiseCore

/// Takes pictures of other apps' windows (ADR 0024). Finds each window in the system's list
/// by its app, its size and the closest origin, as the Accessibility API gives no number.
@MainActor
final class WindowCapture {
    private let service: any CaptureService
    /// The system's list of windows from the last call. Asking for it takes the longest,
    /// and a window that has moved is still found in an older list.
    private var known: [any CapturableWindow]?

    init(service: any CaptureService) {
        self.service = service
    }

    /// Fetches the list of windows ahead of the first picture; a failure is for later.
    func prepare() async {
        known = try? await service.onScreenWindows()
    }

    /// A stand-in showing `windows` side by side as they look now. The pictures are taken
    /// at the same time, as each of them waits on the system.
    func standIn(
        of windows: [AccessibilityWindow], framesPerSecond: Int
    ) async -> Result<any WindowStandIn, WindowSystemError> {
        do {
            let frames = try windows.map { window throws(WindowSystemError) in try window.frame() }
            let list = try await list(holding: windows, frames: frames)
            let found = try zip(windows, frames).map { window, frame in
                guard let match = Self.match(window, frame: frame, in: list) else {
                    throw WindowSystemError.captureFailed
                }
                return (window: match, frame: frame)
            }
            let tasks = found.map { window in
                // swiftlint:disable:next unhandled_throwing_task - the value below rethrows it
                Task { try await service.picture(of: window.window, frame: window.frame) }
            }
            var pictures: [StandInPanel.Picture] = []
            for task in tasks {
                pictures.append(try await task.value)
            }
            Task { await prepare() }
            return .success(
                service.standIn(
                    pictures: pictures, windows: found, framesPerSecond: framesPerSecond))
        } catch let error as WindowSystemError {
            return .failure(error)
        } catch {
            return .failure(.captureFailed)
        }
    }

    /// The known list when it holds all of `windows`, or else a fresh one.
    private func list(
        holding windows: [AccessibilityWindow], frames: [WindowFrame]
    ) async throws -> [any CapturableWindow] {
        if let known,
            zip(windows, frames).allSatisfy({ Self.match($0, frame: $1, in: known) != nil })
        {
            return known
        }
        let fresh = try await service.onScreenWindows()
        known = fresh
        return fresh
    }

    private static func match(
        _ window: AccessibilityWindow, frame: WindowFrame, in list: [any CapturableWindow]
    ) -> (any CapturableWindow)? {
        let processID = window.element.processID
        let candidates = list.filter { $0.processID == processID }
        return WindowMatch.index(of: frame, among: candidates.map(\.frame)).map { candidates[$0] }
    }
}
