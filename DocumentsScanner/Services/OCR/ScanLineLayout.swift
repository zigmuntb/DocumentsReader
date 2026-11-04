import CoreGraphics
import Foundation
import PDFKit

enum ScanLineLayout {
    static func vision(_ lines: [ObservedTextLine]) -> [ScanLine] {
        let placed = lines.compactMap { line -> ScanLine? in
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            let box = line.bounds
            let rect = CGRect(
                x: box.minX,
                y: 1 - box.maxY,
                width: box.width,
                height: box.height
            )
            return ScanLine(index: 0, text: text, bounds: clamped(rect))
        }
        return indexed(sortedTopToBottom(placed))
    }

    static func plainText(_ text: String) -> [ScanLine] {
        let rows = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let count = CGFloat(max(rows.count, 1))
        let slot = 1 / count
        return rows.enumerated().map { index, row in
            let height = min(slot * 0.72, 0.055)
            let y = slot * CGFloat(index) + (slot - height) / 2
            return ScanLine(
                index: index,
                text: String(row),
                bounds: CGRect(x: 0.08, y: y, width: 0.84, height: height)
            )
        }
    }

    /// Line boxes from the PDF text layer, normalized with the origin at the top left.
    static func pdfLines(fileURL: URL, pageNumber: Int) -> [ScanLine]? {
        guard pageNumber > 0,
              let document = PDFDocument(url: fileURL),
              let page = document.page(at: pageNumber - 1),
              let text = page.string else {
            return nil
        }
        let box = page.bounds(for: .mediaBox)
        guard box.width > 1, box.height > 1 else { return nil }

        let nsText = text as NSString
        var lines: [ScanLine] = []
        var location = 0
        while location < nsText.length {
            let range = nsText.lineRange(for: NSRange(location: location, length: 0))
            location = range.location + range.length
            let trimmed = nsText.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let selection = page.selection(for: range) else { continue }
            let raw = selection.bounds(for: page)
            guard raw.width > 0.5, raw.height > 0.5 else { continue }
            let rect = CGRect(
                x: (raw.minX - box.minX) / box.width,
                y: 1 - ((raw.maxY - box.minY) / box.height),
                width: raw.width / box.width,
                height: raw.height / box.height
            )
            lines.append(ScanLine(index: lines.count, text: trimmed, bounds: clamped(rect)))
        }
        return lines.isEmpty ? nil : lines
    }

    private static func sortedTopToBottom(_ lines: [ScanLine]) -> [ScanLine] {
        lines.sorted { lhs, rhs in
            let left = lhs.bounds?.midY ?? 0
            let right = rhs.bounds?.midY ?? 0
            if abs(left - right) > 0.015 {
                return left < right
            }
            return (lhs.bounds?.minX ?? 0) < (rhs.bounds?.minX ?? 0)
        }
    }

    private static func indexed(_ lines: [ScanLine]) -> [ScanLine] {
        lines.enumerated().map { index, line in
            ScanLine(index: index, text: line.text, bounds: line.bounds)
        }
    }

    private static func clamped(_ rect: CGRect) -> CGRect {
        let x = min(max(rect.minX, 0), 1)
        let y = min(max(rect.minY, 0), 1)
        let width = min(max(rect.width, 0), 1 - x)
        let height = min(max(rect.height, 0), 1 - y)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
