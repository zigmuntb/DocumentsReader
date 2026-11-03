import Foundation
import Testing
@testable import DocumentsScanner

struct LeaseTextChunkerTests {
    @Test func shortParagraphsStayInOneChunk() {
        let first = String(repeating: "a", count: 100)
        let second = String(repeating: "b", count: 100)
        let chunks = LeaseTextChunker.chunks(from: [page("\(first)\n\n\(second)")])
        #expect(chunks.count == 1)
        #expect(chunks[0].pieces.map(\.text) == [first, second])
        #expect(chunks[0].prompt.contains("Page index: 1"))
    }

    @Test func paragraphsOverTheBudgetSplit() {
        let first = String(repeating: "a", count: 1_000)
        let second = String(repeating: "b", count: 1_000)
        let chunks = LeaseTextChunker.chunks(from: [page("\(first)\n\n\(second)")])
        #expect(chunks.count == 2)
        #expect(chunks[0].pieces.map(\.text) == [first])
        #expect(chunks[1].pieces.map(\.text) == [second])
    }

    @Test func aLongParagraphSplitsOnWords() {
        let words = (0..<500).map { "word\($0)" }
        let chunks = LeaseTextChunker.chunks(from: [page(words.joined(separator: " "))])
        #expect(chunks.count > 1)
        #expect(chunks.allSatisfy { $0.characterCount <= LeaseTextChunker.maximumCharacters })
        let joined = chunks.flatMap(\.pieces).map(\.text).joined(separator: " ")
        #expect(joined.contains("word0"))
        #expect(joined.contains("word499"))
    }

    @Test func blankPagesProduceNoChunks() {
        let chunks = LeaseTextChunker.chunks(from: [page("   \n\n  ")])
        #expect(chunks.isEmpty)
    }

    private func page(_ text: String) -> RecognizedPage {
        RecognizedPage(index: 1, text: text)
    }
}
