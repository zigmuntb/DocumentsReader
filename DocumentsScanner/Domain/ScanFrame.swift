import CoreGraphics
import Foundation

/// One visual line on the page being read.
struct ScanLine: Equatable, Sendable, Identifiable {
    let index: Int
    let text: String
    /// Normalized rect, origin at the top left of the page. Nil when the line has no position.
    let bounds: CGRect?

    var id: Int { index }
}

enum ScanActivity: Equatable, Sendable {
    /// The page is on screen and the beam is still looking for lines.
    case sweeping
    /// Lines are known and the beam can pick them off the page.
    case readingLines
}

/// What the processing screen shows for the page in front of the reader.
struct ScanFrame: Equatable, Sendable {
    let pageIndex: Int
    let pageCount: Int
    let imageJPEG: Data?
    let lines: [ScanLine]
    let activity: ScanActivity
}

enum ScanTiming {
    /// Long enough to see lines lift, short enough that a text-layer PDF does not stall.
    static func liftDuration(lineCount: Int) -> TimeInterval {
        let scaled = Double(max(lineCount, 1)) * 0.07
        return min(2.4, max(0.8, scaled))
    }
}
