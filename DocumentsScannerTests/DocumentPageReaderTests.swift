import Foundation
import Testing
import UIKit
@testable import DocumentsScanner

struct DocumentPageReaderTests {
    @Test func pdfTextLayerSkipsRasterAndBlankPageIsRendered() async throws {
        let url = try Self.makePDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let pages = try await DocumentPageReader().prepare(.pages([.file(url)]))
        #expect(pages.count == 2)
        #expect(pages[0].embeddedText?.contains("Tenant shall pay rent") == true)
        #expect(pages[0].imageData == nil)
        #expect(pages[0].previewSource?.pdfPage == 1)
        #expect(pages[1].embeddedText == nil)
        #expect((pages[1].imageData?.isEmpty) == false)
    }

    private static func makePDF() throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        let data = renderer.pdfData { context in
            context.beginPage()
            let text = "Tenant shall pay rent of $1500." as NSString
            text.draw(at: CGPoint(x: 20, y: 40), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
            context.beginPage()
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        try data.write(to: url)
        return url
    }
}
