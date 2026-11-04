import CoreGraphics
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
        let pages = try await recognizer.recognize(.pages([.image(Data([1]))])) { _ in }
        #expect(pages == [RecognizedPage(index: 0, text: "payment due")])
    }

    @Test func skipsVisionWhenThePageHasATextLayer() async throws {
        let recognizer = LeaseTextRecognizer(
            pages: FixedPages(pages: [
                PreparedPage(index: 0, embeddedText: "hello   world", imageData: nil)
            ]),
            vision: FailingVision()
        )
        let pages = try await recognizer.recognize(.pages([.image(Data())])) { _ in }
        #expect(pages == [RecognizedPage(index: 0, text: "hello world")])
    }

    @Test func publishesThePageBeforeAndAfterItIsRead() async throws {
        let log = FrameLog()
        let recognizer = LeaseTextRecognizer(
            pages: FixedPages(pages: [
                PreparedPage(index: 0, embeddedText: "Rent is due.\nTerm is one year.", imageData: nil)
            ]),
            vision: FailingVision()
        )

        _ = try await recognizer.recognize(.pages([.image(Data())])) { frame in
            log.record(frame)
        }

        #expect(log.activities == [.sweeping, .readingLines])
        #expect(log.lifted == ["Rent is due.", "Term is one year."])
    }
}

private struct FixedPages: DocumentScanning {
    let pages: [PreparedPage]

    func prepare(_ job: RecognitionJob) async throws -> [PreparedPage] {
        pages
    }
}

private final class FrameLog: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [ScanActivity] = []
    private var lines: [String] = []

    func record(_ frame: ScanFrame) {
        lock.lock()
        recorded.append(frame.activity)
        if frame.activity == .readingLines {
            lines = frame.lines.map(\.text)
        }
        lock.unlock()
    }

    var activities: [ScanActivity] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    var lifted: [String] {
        lock.lock()
        defer { lock.unlock() }
        return lines
    }
}

private struct ScriptedVision: VisionTextReading {
    let text: String

    func recognizeText(in imageData: Data) async throws -> VisionPage {
        VisionPage(
            lines: [ObservedTextLine(text: text, bounds: CGRect(x: 0.1, y: 0.7, width: 0.8, height: 0.08))],
            displayJPEG: imageData
        )
    }
}

private struct FailingVision: VisionTextReading {
    func recognizeText(in imageData: Data) async throws -> VisionPage {
        throw DocumentReadError.recognitionFailed
    }
}
