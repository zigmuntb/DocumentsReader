import Foundation

protocol LeaseAnalyzing: Sendable {
    func analyze(
        _ document: RecognizedDocument,
        onChunk: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> LeaseReading
}
