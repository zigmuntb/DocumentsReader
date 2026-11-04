import CoreGraphics
import Foundation
import ImageIO

/// Bakes image orientation into the pixels and caps the long edge.
/// Vision boxes are measured on this image, and the scan screen draws the same pixels.
enum PageImageNormalizer {
    static func cgImage(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw DocumentReadError.unreadableFile
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2000
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw DocumentReadError.unreadableFile
        }
        return image
    }
}
