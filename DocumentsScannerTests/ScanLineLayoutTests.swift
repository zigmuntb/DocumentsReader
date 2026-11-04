import CoreGraphics
import Foundation
import Testing
import UIKit
@testable import DocumentsScanner

struct ScanLineLayoutTests {
    @Test func visionBoxesFlipToTheTopLeft() {
        let lines = ScanLineLayout.vision([
            ObservedTextLine(text: "Rent", bounds: CGRect(x: 0.1, y: 0.7, width: 0.5, height: 0.08)),
            ObservedTextLine(text: "  ", bounds: CGRect(x: 0, y: 0, width: 1, height: 0.1))
        ])

        #expect(lines.map(\.text) == ["Rent"])
        let bounds = lines[0].bounds
        #expect(bounds?.minX == 0.1)
        #expect(abs((bounds?.minY ?? 0) - 0.22) < 0.001)
        #expect(bounds?.width == 0.5)
        #expect(bounds?.height == 0.08)
    }

    @Test func plainTextKeepsEachNonEmptyRow() {
        let lines = ScanLineLayout.plainText("Rent is due.\n\nTerm is one year.")
        #expect(lines.map(\.text) == ["Rent is due.", "Term is one year."])
        #expect(lines[0].bounds?.minY ?? 1 < lines[1].bounds?.minY ?? 0)
    }

    @Test func pdfLinesSitOnTheTextLayer() throws {
        let url = try Self.makePDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let lines = ScanLineLayout.pdfLines(fileURL: url, pageNumber: 1)
        #expect(lines?.map(\.text) == ["Tenant shall pay rent of $1500."])
        let bounds = try #require(lines?.first?.bounds)
        #expect(bounds.minX >= 0 && bounds.maxX <= 1)
        #expect(bounds.minY >= 0 && bounds.maxY <= 1)
        #expect(bounds.width > 0.05)
        #expect(bounds.minY < 0.5)
    }

    private static func makePDF() throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        let data = renderer.pdfData { context in
            context.beginPage()
            let text = "Tenant shall pay rent of $1500." as NSString
            text.draw(at: CGPoint(x: 20, y: 40), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        try data.write(to: url)
        return url
    }
}
