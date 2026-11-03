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
        onPage: @escaping @Sendable (Int, Int) -> Void
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
        for (offset, page) in prepared.enumerated() {
            try Task.checkCancellation()
            let raw = try await text(for: page)
            recognized.append(
                RecognizedPage(index: page.index, text: LeaseTextNormalizer.normalize(raw))
            )
            onPage(offset + 1, prepared.count)
        }
        return recognized
    }

    private func text(for page: PreparedPage) async throws -> String {
        if let embedded = page.embeddedText,
           !embedded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return embedded
        }
        guard let imageData = page.imageData else { return "" }
        do {
            return try await vision.recognizeText(in: imageData)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as DocumentReadError {
            throw error
        } catch {
            throw DocumentReadError.recognitionFailed
        }
    }
}
