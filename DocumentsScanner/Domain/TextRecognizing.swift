protocol TextRecognizing: Sendable {
    func recognize(
        _ job: RecognitionJob,
        onPage: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> [RecognizedPage]
}
