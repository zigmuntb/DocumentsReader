import Foundation

enum LeaseTextChunker {
    /// The on-device window is 4096 tokens. Instructions and the response schema take a large share, so each excerpt stays near this many characters.
    static let maximumCharacters = 1_800

    static func chunks(from pages: [RecognizedPage]) -> [LeaseTextChunk] {
        var chunks: [LeaseTextChunk] = []
        var current: [ChunkPiece] = []
        var currentCount = 0

        func flush() {
            guard !current.isEmpty else { return }
            chunks.append(LeaseTextChunk(pieces: current))
            current.removeAll()
            currentCount = 0
        }

        for page in pages {
            for paragraph in paragraphs(in: page.text) {
                for piece in split(paragraph, pageIndex: page.index) {
                    if currentCount > 0, currentCount + piece.text.count > maximumCharacters {
                        flush()
                    }
                    current.append(piece)
                    currentCount += piece.text.count
                    if currentCount >= maximumCharacters {
                        flush()
                    }
                }
            }
        }
        flush()
        return chunks
    }

    private static func paragraphs(in text: String) -> [String] {
        let parts = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if parts.isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        }
        return parts
    }

    private static func split(_ paragraph: String, pageIndex: Int) -> [ChunkPiece] {
        guard paragraph.count > maximumCharacters else {
            return [ChunkPiece(pageIndex: pageIndex, text: paragraph)]
        }
        var pieces: [ChunkPiece] = []
        var rest = paragraph[...]
        while !rest.isEmpty {
            if rest.count <= maximumCharacters {
                let text = String(rest).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    pieces.append(ChunkPiece(pageIndex: pageIndex, text: text))
                }
                break
            }
            let end = rest.index(rest.startIndex, offsetBy: maximumCharacters)
            let boundary = rest[..<end].lastIndex(of: " ") ?? end
            let cut = boundary == rest.startIndex ? end : boundary
            let text = String(rest[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                pieces.append(ChunkPiece(pageIndex: pageIndex, text: text))
            }
            rest = rest[cut...].drop(while: { $0 == " " })
        }
        return pieces
    }
}
