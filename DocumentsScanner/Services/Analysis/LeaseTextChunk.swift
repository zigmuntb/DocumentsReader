import Foundation

struct ChunkPiece: Equatable, Sendable {
    let pageIndex: Int
    let text: String
}

struct LeaseTextChunk: Equatable, Sendable {
    let pieces: [ChunkPiece]

    var characterCount: Int {
        pieces.reduce(0) { $0 + $1.text.count }
    }

    var prompt: String {
        pieces.map { "Page index: \($0.pageIndex)\n\($0.text)" }.joined(separator: "\n\n")
    }

    /// One split, used when the model reports that the excerpt did not fit.
    func halves() -> (LeaseTextChunk, LeaseTextChunk)? {
        guard characterCount >= 400 else { return nil }
        if pieces.count >= 2, let split = splitPieces() {
            return split
        }
        guard let piece = pieces.first else { return nil }
        let text = piece.text
        let middle = text.index(text.startIndex, offsetBy: text.count / 2)
        let boundary = text[..<middle].lastIndex(of: " ") ?? middle
        let left = String(text[..<boundary]).trimmingCharacters(in: .whitespacesAndNewlines)
        let right = String(text[boundary...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !left.isEmpty, !right.isEmpty else { return nil }
        return (
            LeaseTextChunk(pieces: [ChunkPiece(pageIndex: piece.pageIndex, text: left)]),
            LeaseTextChunk(pieces: [ChunkPiece(pageIndex: piece.pageIndex, text: right)])
        )
    }

    private func splitPieces() -> (LeaseTextChunk, LeaseTextChunk)? {
        var left: [ChunkPiece] = []
        var leftCount = 0
        let target = characterCount / 2
        for piece in pieces {
            if left.isEmpty || leftCount < target {
                left.append(piece)
                leftCount += piece.text.count
            } else {
                break
            }
        }
        let right = Array(pieces.dropFirst(left.count))
        guard !left.isEmpty, !right.isEmpty else { return nil }
        return (LeaseTextChunk(pieces: left), LeaseTextChunk(pieces: right))
    }
}
