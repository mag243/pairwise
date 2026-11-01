import Foundation

/// Predicts where a dragged window is going, for a smooth stand-in: a place and a speed
/// carried from frame to frame. The speed is the pointer's, because the pointer moves
/// first and the window follows it (ADR 0021).
public struct MotionPrediction: Sendable {
    /// How far the place may be from where the window will be, in points. This bounds how
    /// far ahead the stand-in gets while the window hangs.
    public static let reach = 24.0
    /// The share of a new speed taken on each frame; the rest is the speed so far.
    private static let speedSmoothing = 0.5
    /// The share of the way to where the window will be that the place goes on each frame.
    private static let pull = 0.3
    /// Below this speed, in points a second, the pointer counts as resting.
    private static let restingSpeed = 5.0
    /// Within this distance, in points, a resting place goes straight to the window.
    private static let settleDistance = 0.5

    private var place: ScreenPoint?
    private var lastPointer = ScreenPoint(x: 0, y: 0)
    private var lastTime: TimeInterval = 0
    private var speedX = 0.0
    private var speedY = 0.0

    public init() {}

    /// The stand-in's place for this frame, with the window's own place `window`, the
    /// pointer at `pointer`, and `lookAhead` seconds to predict.
    /// Postcondition: once the pointer has rested for long enough, this is `window`.
    public mutating func place(
        forWindowAt window: ScreenPoint, pointer: ScreenPoint, at time: TimeInterval,
        lookingAhead lookAhead: TimeInterval
    ) -> ScreenPoint {
        defer {
            lastPointer = pointer
            lastTime = time
        }
        guard let last = place else {
            place = window
            return window
        }
        let elapsed = time - lastTime
        guard elapsed > 0 else { return last }
        updateSpeed(pointer: pointer, elapsed: elapsed)
        let spot = ScreenPoint(
            x: window.x + speedX * lookAhead, y: window.y + speedY * lookAhead)
        let next = nextPlace(from: last, toward: spot, elapsed: elapsed)
        place = next
        return next
    }

    private mutating func updateSpeed(pointer: ScreenPoint, elapsed: TimeInterval) {
        speedX += Self.speedSmoothing * ((pointer.x - lastPointer.x) / elapsed - speedX)
        speedY += Self.speedSmoothing * ((pointer.y - lastPointer.y) / elapsed - speedY)
        if hypot(speedX, speedY) < Self.restingSpeed {
            speedX = 0
            speedY = 0
        }
    }

    private func nextPlace(
        from last: ScreenPoint, toward spot: ScreenPoint, elapsed: TimeInterval
    ) -> ScreenPoint {
        let isResting = speedX == 0 && speedY == 0
        if isResting, last.distance(to: spot) < Self.settleDistance { return spot }
        let movedX = last.x + speedX * elapsed
        let movedY = last.y + speedY * elapsed
        let pulled = ScreenPoint(
            x: movedX + Self.pull * (spot.x - movedX), y: movedY + Self.pull * (spot.y - movedY))
        let distance = pulled.distance(to: spot)
        guard distance > Self.reach else { return pulled }
        let share = Self.reach / distance
        return ScreenPoint(
            x: spot.x + (pulled.x - spot.x) * share, y: spot.y + (pulled.y - spot.y) * share)
    }
}
