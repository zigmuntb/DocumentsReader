import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageJPEG {
    static func data(from image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw DocumentReadError.unreadableFile
        }
        let options = [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else {
            throw DocumentReadError.unreadableFile
        }
        return data as Data
    }
}
