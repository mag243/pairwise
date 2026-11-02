/// Where a picture of a window can best be divided when its window narrows or widens: a column
/// with little in it, so that text is not cut through or stretched into streaks (ADR 0048).
public enum QuietColumn {
    /// How many columns away a column is compared with, as a share of the picture's width.
    /// Far enough to see past the stroke of a letter.
    private static let reachShare = 64

    /// The column in the middle half of a picture that differs least from the columns on either
    /// side, and of those the closest to the middle.
    /// Precondition: `gray` holds `height` rows of `width` values, and `width` is above 0.
    public static func index(inGray gray: [UInt8], width: Int, height: Int) -> Int {
        precondition(width > 0 && gray.count == width * height, "gray holds height rows of width")
        let reach = max(width / reachShare, 1)
        let middle = width / 2
        var best = min(middle, width - 1)
        var bestScore = Int.max
        for column in max(width / 4, 0)..<max(width * 3 / 4, 1) {
            let score = busyness(of: column, reach: reach, gray: gray, width: width, height: height)
            let isCloser = abs(column - middle) < abs(best - middle)
            if score < bestScore || (score == bestScore && isCloser) {
                best = column
                bestScore = score
            }
        }
        return best
    }

    private static func busyness(
        of column: Int, reach: Int, gray: [UInt8], width: Int, height: Int
    ) -> Int {
        let left = max(column - reach, 0)
        let right = min(column + reach, width - 1)
        var total = 0
        for row in 0..<height {
            let start = row * width
            let value = Int(gray[start + column])
            total += abs(value - Int(gray[start + left])) + abs(value - Int(gray[start + right]))
        }
        return total
    }
}
