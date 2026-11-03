import Foundation

@MainActor
final class InMemoryDocumentSessionStore: DocumentSessionStoring {
    private var jobs: [UUID: RecognitionJob] = [:]
    private var documents: [UUID: RecognizedDocument] = [:]
    private var readings: [UUID: LeaseReading] = [:]
    private var createdAt: [UUID: Date] = [:]

    func stage(_ job: RecognitionJob) -> UUID {
        let id = UUID()
        jobs[id] = job
        return id
    }

    func job(id: UUID) -> RecognitionJob? {
        jobs[id]
    }

    func save(_ document: RecognizedDocument) {
        documents[document.id] = document
    }

    func document(id: UUID) -> RecognizedDocument? {
        documents[id]
    }

    func save(_ reading: LeaseReading) {
        if createdAt[reading.document.id] == nil {
            createdAt[reading.document.id] = Date()
        }
        readings[reading.document.id] = reading
        documents[reading.document.id] = reading.document
    }

    func reading(id: UUID) -> LeaseReading? {
        readings[id]
    }

    func history() throws -> [LeaseHistoryEntry] {
        readings.values
            .map { reading in
                LeaseHistoryEntry.make(
                    reading: reading,
                    createdAt: createdAt[reading.document.id] ?? Date()
                )
            }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id.uuidString > rhs.id.uuidString
            }
    }
}
