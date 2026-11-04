import Foundation

/// Where a text-layer PDF page can be drawn for the scan screen without running OCR.
struct PageSource: Equatable, Sendable {
    let fileURL: URL
    /// 1-based page number, matching `PDFPageRasterizer`.
    let pdfPage: Int
}

/// A page ready for recognition. Text-layer PDF pages carry `embeddedText` and skip OCR.
struct PreparedPage: Equatable, Sendable {
    let index: Int
    let embeddedText: String?
    let imageData: Data?
    let previewSource: PageSource?

    init(
        index: Int,
        embeddedText: String?,
        imageData: Data?,
        previewSource: PageSource? = nil
    ) {
        self.index = index
        self.embeddedText = embeddedText
        self.imageData = imageData
        self.previewSource = previewSource
    }
}
