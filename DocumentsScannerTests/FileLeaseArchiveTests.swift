import Foundation
import Testing
@testable import DocumentsScanner

@MainActor
struct FileLeaseArchiveTests {
    @Test func aFinishedReadingSurvivesANewArchive() throws {
        let directory = try makeDirectory()
        let archive = FileLeaseArchive(directory: directory)
        let image = Data([0xFF, 0xD8, 0xFF])
        let id = archive.stage(.pages([.image(image)]))
        let reading = sampleReading(id: id, text: "Residential lease\nRent is $1500.")
        archive.save(reading)

        let source = directory
            .appendingPathComponent("readings")
            .appendingPathComponent(id.uuidString)
            .appendingPathComponent("sources")
            .appendingPathComponent("page-0.jpg")
        #expect(try Data(contentsOf: source) == image)

        let again = FileLeaseArchive(directory: directory)
        #expect(again.reading(id: id) == reading)
        let entries = try again.history()
        #expect(entries.map(\.id) == [id])
        #expect(entries.first?.title == "Residential lease")
        #expect(entries.first?.summary == .checklist(itemCount: 3))
    }

    @Test func rewritingKeepsTheOriginalDate() throws {
        let directory = try makeDirectory()
        let reading = sampleReading(id: UUID(), text: "Residential lease")
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        try write(StoredLeaseRecord(reading: reading, createdAt: createdAt), to: directory)
        let archive = FileLeaseArchive(directory: directory)
        archive.save(reading)
        let entries = try archive.history()
        #expect(entries.first?.createdAt == createdAt)
    }

    @Test func aPartialDocumentIsNotHistory() throws {
        let archive = FileLeaseArchive(directory: try makeDirectory())
        let id = archive.stage(.pages([.image(Data([1]))]))
        archive.save(
            RecognizedDocument(
                id: id,
                pages: [RecognizedPage(index: 0, text: "Residential lease")],
                isSparse: false
            )
        )
        #expect(try archive.history().isEmpty)
    }

    @Test func aBrokenRecordIsSkipped() throws {
        let directory = try makeDirectory()
        let kept = sampleReading(id: UUID(), text: "Kept lease")
        try write(StoredLeaseRecord(reading: kept, createdAt: Date(timeIntervalSince1970: 1_700_000_000)), to: directory)
        let brokenID = UUID()
        let folder = directory
            .appendingPathComponent("readings")
            .appendingPathComponent(brokenID.uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let unknownVersion = """
        {"createdAt":"2023-11-14T22:13:20Z","document":{"id":"\(brokenID.uuidString)","isSparse":false,"pages":[]},"outcome":{"checklist":null,"fallback":"sparseText","kind":"fallback"},"version":99}
        """
        try Data(unknownVersion.utf8).write(to: folder.appendingPathComponent("reading.json"))
        let entries = try FileLeaseArchive(directory: directory).history()
        #expect(entries.map(\.id) == [kept.document.id])
    }

    @Test func aMissingFolderIsAnEmptyHistory() throws {
        let archive = FileLeaseArchive(directory: try makeDirectory())
        #expect(try archive.history().isEmpty)
    }

    @Test func anUnreadableFolderThrows() throws {
        let directory = try makeDirectory()
        let readings = directory.appendingPathComponent("readings")
        try Data([1]).write(to: readings)
        let archive = FileLeaseArchive(directory: directory)
        #expect(throws: HistoryStoreError.unreadable) {
            try archive.history()
        }
    }

    @Test func aFailedWriteStillOpensTheCurrentReading() throws {
        let blocked = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data([1]).write(to: blocked)
        let archive = FileLeaseArchive(directory: blocked)
        let reading = sampleReading(id: UUID(), text: "Residential lease")
        archive.save(reading)
        #expect(archive.reading(id: reading.document.id) == reading)
    }

    @Test func theTitleUsesTheFirstLineAndTheFallbackHasNoCount() {
        let long = String(repeating: "a", count: 90)
        let titled = LeaseHistoryEntry.make(
            reading: sampleReading(id: UUID(), text: "  \n\(long)"),
            createdAt: Date()
        )
        #expect(titled.title?.count == 80)
        #expect(titled.title?.hasSuffix("...") == true)

        let fallback = LeaseHistoryEntry.make(
            reading: LeaseReading(
                document: RecognizedDocument(id: UUID(), pages: [], isSparse: true),
                outcome: .fallback(.sparseText)
            ),
            createdAt: Date()
        )
        #expect(fallback.title == nil)
        #expect(fallback.summary == .textOnly)
    }

    private func sampleReading(id: UUID, text: String) -> LeaseReading {
        LeaseReading(
            document: RecognizedDocument(
                id: id,
                pages: [RecognizedPage(index: 0, text: text)],
                isSparse: false
            ),
            outcome: .checklist(
                LeaseChecklist(
                    parties: [item("Tenant")],
                    money: [item("Rent"), item("Deposit")],
                    dates: [],
                    obligations: [],
                    questionsBeforeSigning: []
                )
            )
        )
    }

    private func item(_ title: String) -> ChecklistItem {
        ChecklistItem(
            id: UUID(),
            title: title,
            plainExplanation: "Shown in plain words.",
            quote: "Residential lease",
            pageIndex: 0,
            severity: .check
        )
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func write(_ record: StoredLeaseRecord, to directory: URL) throws {
        let folder = directory
            .appendingPathComponent("readings")
            .appendingPathComponent(record.document.id.uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(record).write(to: folder.appendingPathComponent("reading.json"))
    }
}
