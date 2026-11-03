import Foundation
import PDFKit
import UniformTypeIdentifiers

struct DocumentPageReader: DocumentScanning {
    func prepare(_ job: RecognitionJob) async throws -> [PreparedPage] {
        var prepared: [PreparedPage] = []
        for payload in job.pages {
            try Task.checkCancellation()
            let pages = try pages(for: payload)
            for page in pages {
                prepared.append(
                    PreparedPage(
                        index: prepared.count,
                        embeddedText: page.embeddedText,
                        imageData: page.imageData
                    )
                )
            }
        }
        guard !prepared.isEmpty else { throw DocumentReadError.noPages }
        return prepared
    }

    private func pages(for payload: PagePayload) throws -> [PreparedPage] {
        switch payload {
        case .image(let data):
            return [PreparedPage(index: 0, embeddedText: nil, imageData: data)]
        case .file(let url):
            return try pages(at: url)
        }
    }

    private func pages(at url: URL) throws -> [PreparedPage] {
        if isPDF(url) {
            return try pdfPages(at: url)
        }
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { throw DocumentReadError.unreadableFile }
        return [PreparedPage(index: 0, embeddedText: nil, imageData: data)]
    }

    private func pdfPages(at url: URL) throws -> [PreparedPage] {
        guard let document = PDFDocument(url: url) else {
            throw DocumentReadError.unreadableFile
        }
        guard document.pageCount > 0 else { throw DocumentReadError.noPages }

        var pages: [PreparedPage] = []
        for index in 0..<document.pageCount {
            let text = document.page(at: index)?.string ?? ""
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let image = try PDFPageRasterizer.jpegData(documentURL: url, pageNumber: index + 1)
                pages.append(PreparedPage(index: index, embeddedText: nil, imageData: image))
            } else {
                pages.append(PreparedPage(index: index, embeddedText: text, imageData: nil))
            }
        }
        return pages
    }

    private func isPDF(_ url: URL) -> Bool {
        if UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true {
            return true
        }
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        let header = try? handle.read(upToCount: 5)
        return header == Data("%PDF-".utf8)
    }
}
