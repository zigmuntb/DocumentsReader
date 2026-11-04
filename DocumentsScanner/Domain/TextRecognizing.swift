protocol TextRecognizing: Sendable {
    func recognize(
        _ job: RecognitionJob,
        onPage: @escaping @Sendable (ScanFrame) -> Void
    ) async throws -> [RecognizedPage]
}
