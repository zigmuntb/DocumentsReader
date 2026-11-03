protocol DocumentScanning: Sendable {
    func prepare(_ job: RecognitionJob) async throws -> [PreparedPage]
}
