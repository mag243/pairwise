import SwiftUI

/// What a copy of the app shows for the stress test: something that changes all the time, to
/// tell whether live pictures stay alive (ADR 0029). It is not for users, so it has no text.
struct AnimatedTestView: View {
    private static let refresh = 1.0 / 60
    private static let cycle = 2.0
    private static let width: CGFloat = 400
    private static let height: CGFloat = 300

    var body: some View {
        TimelineView(.periodic(from: .now, by: Self.refresh)) { context in
            let phase =
                context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: Self.cycle) / Self.cycle
            Color(hue: phase, saturation: 1, brightness: 1)
        }
        .frame(width: Self.width, height: Self.height)
    }
}
