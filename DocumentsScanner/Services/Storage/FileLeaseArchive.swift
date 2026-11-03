import Foundation

/// Finished readings live as JSON plus the original page files. A scan that is still running stays in memory.
@MainActor
final class FileLeaseArchive: DocumentSessionStoring {
    private let directory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var jobs: [UUID: RecognitionJob] = [:]
    private var documents: [UUID: RecognizedDocument] = [:]
    private var readings: [UUID: LeaseReading] = [:]

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    static func live() -> FileLeaseArchive {
        FileLeaseArchive(
            directory: URL.applicationSupportDirectory.appendingPathComponent("LeaseAudit", isDirectory: true)
        )
    }

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
        documents[id] ?? load(id)?.document
    }

    func save(_ reading: LeaseReading) {
        let id = reading.document.id
        documents[id] = reading.document
        readings[id] = reading
        let createdAt = loadRecord(id: id)?.createdAt ?? Date()
        persist(reading, createdAt: createdAt)
    }

    func reading(id: UUID) -> LeaseReading? {
        readings[id] ?? load(id)
    }

    func history() throws -> [LeaseHistoryEntry] {
        let folder = readingsFolder
        guard fileManager.fileExists(atPath: folder.path) else { return [] }
        let folders: [URL]
        do {
            folders = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw HistoryStoreError.unreadable
        }
        return folders.compactMap { loadRecord(in: $0)?.entry() }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id.uuidString > rhs.id.uuidString
            }
    }

    private var readingsFolder: URL {
        directory.appendingPathComponent("readings", isDirectory: true)
    }

    private func folder(for id: UUID) -> URL {
        readingsFolder.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private func persist(_ reading: LeaseReading, createdAt: Date) {
        let folder = folder(for: reading.document.id)
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let data = try encoder.encode(StoredLeaseRecord(reading: reading, createdAt: createdAt))
            try data.write(to: folder.appendingPathComponent("reading.json"), options: .atomic)
            copySources(for: reading.document.id, into: folder)
        } catch {
            return
        }
    }

    private func copySources(for id: UUID, into folder: URL) {
        guard let job = jobs[id] else { return }
        let sources = folder.appendingPathComponent("sources", isDirectory: true)
        if fileManager.fileExists(atPath: sources.path) {
            try? fileManager.removeItem(at: sources)
        }
        guard (try? fileManager.createDirectory(at: sources, withIntermediateDirectories: true)) != nil else { return }
        for (offset, page) in job.pages.enumerated() {
            switch page {
            case .image(let data):
                try? data.write(to: sources.appendingPathComponent("page-\(offset).jpg"), options: .atomic)
            case .file(let url):
                let ext = url.pathExtension.isEmpty ? "bin" : url.pathExtension
                let destination = sources.appendingPathComponent("page-\(offset).\(ext)")
                try? fileManager.copyItem(at: url, to: destination)
            }
        }
    }

    private func load(_ id: UUID) -> LeaseReading? {
        guard let reading = loadRecord(id: id)?.reading() else { return nil }
        readings[id] = reading
        documents[id] = reading.document
        return reading
    }

    private func loadRecord(id: UUID) -> StoredLeaseRecord? {
        loadRecord(in: folder(for: id))
    }

    private func loadRecord(in folder: URL) -> StoredLeaseRecord? {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("reading.json")) else { return nil }
        return try? decoder.decode(StoredLeaseRecord.self, from: data)
    }
}
