import Foundation

@MainActor
protocol DocumentSessionStoring: AnyObject {
    @discardableResult
    func stage(_ job: RecognitionJob) -> UUID
    func job(id: UUID) -> RecognitionJob?
    func save(_ document: RecognizedDocument)
    func document(id: UUID) -> RecognizedDocument?
    func save(_ reading: LeaseReading)
    func reading(id: UUID) -> LeaseReading?
    func history() throws -> [LeaseHistoryEntry]
}
