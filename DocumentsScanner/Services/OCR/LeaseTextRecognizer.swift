import Foundation

struct LeaseTextRecognizer: TextRecognizing {
    private let pages: any DocumentScanning
    private let vision: any VisionTextReading

    init(
        pages: any DocumentScanning = DocumentPageReader(),
        vision: any VisionTextReading = VisionTextReader()
    ) {
        self.pages = pages
        self.vision = vision
    }

    func recognize(
        _ job: RecognitionJob,
        onPage: @escaping @Sendable (ScanFrame) -> Void
    ) async throws -> [RecognizedPage] {
        let prepared: [PreparedPage]
        do {
            prepared = try await pages.prepare(job)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DocumentReadError {
            throw error
        } catch {
            throw DocumentReadError.unreadableFile
        }

        var recognized: [RecognizedPage] = []
        for page in prepared {
            try Task.checkCancellation()
            let preview = previewImage(for: page)
            onPage(ScanFrame(
                pageIndex: page.index,
                pageCount: prepared.count,
                imageJPEG: preview,
                lines: [],
                activity: .sweeping
            ))
            let read = try await contents(of: page, preview: preview)
            onPage(ScanFrame(
                pageIndex: page.index,
                pageCount: prepared.count,
                imageJPEG: read.image,
                lines: read.lines,
                activity: .readingLines
            ))
            recognized.append(
                RecognizedPage(index: page.index, text: LeaseTextNormalizer.normalize(read.raw))
            )
        }
        return recognized
    }

    private func previewImage(for page: PreparedPage) -> Data? {
        if let imageData = page.imageData { return imageData }
        guard let source = page.previewSource else { return nil }
        return try? PDFPageRasterizer.jpegData(documentURL: source.fileURL, pageNumber: source.pdfPage)
    }

    private func contents(of page: PreparedPage, preview: Data?) async throws -> PageContents {
        if let embedded = page.embeddedText,
           !embedded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let lines = positionedLines(in: embedded, source: page.previewSource)
            return PageContents(raw: embedded, lines: lines, image: preview)
        }
        guard let imageData = page.imageData else {
            return PageContents(raw: "", lines: [], image: preview)
        }
        do {
            let seen = try await vision.recognizeText(in: imageData)
            return PageContents(
                raw: seen.lines.map(\.text).joined(separator: "\n"),
                lines: ScanLineLayout.vision(seen.lines),
                image: seen.displayJPEG
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DocumentReadError {
            throw error
        } catch {
            throw DocumentReadError.recognitionFailed
        }
    }

    private func positionedLines(in text: String, source: PageSource?) -> [ScanLine] {
        if let source, let lines = ScanLineLayout.pdfLines(fileURL: source.fileURL, pageNumber: source.pdfPage) {
            return lines
        }
        return ScanLineLayout.plainText(text)
    }
}

private struct PageContents {
    var raw: String
    var lines: [ScanLine]
    var image: Data?
}
