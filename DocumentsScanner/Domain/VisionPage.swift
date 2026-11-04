import CoreGraphics
import Foundation

struct ObservedTextLine: Equatable, Sendable {
    let text: String
    /// Vision box: normalized, origin at the bottom left of the image.
    let bounds: CGRect
}

struct VisionPage: Equatable, Sendable {
    let lines: [ObservedTextLine]
    /// Upright JPEG of the pixels Vision measured, so highlights sit on the same image.
    let displayJPEG: Data
}
