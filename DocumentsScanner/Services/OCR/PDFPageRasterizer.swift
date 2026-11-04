import CoreGraphics
import Foundation

enum PDFPageRasterizer {
    /// Long edge stays under 2000 px. Letter size is rendered at 2x, which is enough for accurate OCR.
    static func jpegData(documentURL: URL, pageNumber: Int) throws -> Data {
        guard let document = CGPDFDocument(documentURL as CFURL),
              let page = document.page(at: pageNumber) else {
            throw DocumentReadError.unreadableFile
        }

        let box = page.getBoxRect(.mediaBox)
        let longest = max(box.width, box.height)
        let scale = min(2, 2000 / max(longest, 1))
        let width = max(Int((box.width * scale).rounded()), 1)
        let height = max(Int((box.height * scale).rounded()), 1)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            throw DocumentReadError.unreadableFile
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        context.translateBy(x: -box.origin.x, y: -box.origin.y)
        context.drawPDFPage(page)
        context.restoreGState()

        guard let image = context.makeImage() else {
            throw DocumentReadError.unreadableFile
        }
        return try ImageJPEG.data(from: image)
    }
}
