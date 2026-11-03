import Foundation
import Testing
@testable import DocumentsScanner

struct LeaseTextRecognizerTests {
    @Test func normalizesImageTextFromVision() async throws {
        let recognizer = LeaseTextRecognizer(
            pages: FixedPages(pages: [
                PreparedPage(index: 0, embeddedText: nil, imageData: Data([1]))
            ]),
            vision: ScriptedVision(text: "pay-\nment  due")
        )
        let pages = try await recognizer.recognize(.pages([.image(Data([1]))])) { _, _ in }
        #expect(pages == [RecognizedPage(index: 0, text: "payment due")])
    }

    @Test func skipsVisionWhenThePageHasATextLayer() async throws {
        let recognizer = LeaseTextRecognizer(
            pages: FixedPages(pages: [
                PreparedPage(index: 0, embeddedText: "hello   world", imageData: nil)
            ]),
            vision: FailingVision()
        )
        let pages = try await recognizer.recognize(.pages([.image(Data())])) { _, _ in }
        #expect(pages == [RecognizedPage(index: 0, text: "hello world")])
    }
}

private struct FixedPages: DocumentScanning {
    let pages: [PreparedPage]

    func prepare(_ job: RecognitionJob) async throws -> [PreparedPage] {
        pages
    }
}

private struct ScriptedVision: VisionTextReading {
    let text: String

    func recognizeText(in imageData: Data) async throws -> String {
        text
    }
}

private struct FailingVision: VisionTextReading {
    func recognizeText(in imageData: Data) async throws -> String {
        throw DocumentReadError.recognitionFailed
    }
}
