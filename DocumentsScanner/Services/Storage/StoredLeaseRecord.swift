import Foundation

struct StoredLeaseRecord: Codable {
    static let currentVersion = 1

    var version: Int
    var createdAt: Date
    var document: StoredDocument
    var outcome: StoredOutcome

    init(reading: LeaseReading, createdAt: Date) {
        version = Self.currentVersion
        self.createdAt = createdAt
        document = StoredDocument(reading.document)
        outcome = StoredOutcome(reading.outcome)
    }

    func reading() -> LeaseReading? {
        guard version == Self.currentVersion else { return nil }
        guard let recognized = document.recognized(), let outcome = outcome.resolved() else { return nil }
        return LeaseReading(document: recognized, outcome: outcome)
    }

    func entry() -> LeaseHistoryEntry? {
        guard let reading = reading() else { return nil }
        return LeaseHistoryEntry.make(reading: reading, createdAt: createdAt)
    }
}

struct StoredDocument: Codable {
    var id: UUID
    var isSparse: Bool
    var pages: [StoredPage]

    init(_ document: RecognizedDocument) {
        id = document.id
        isSparse = document.isSparse
        pages = document.pages.map(StoredPage.init)
    }

    func recognized() -> RecognizedDocument? {
        RecognizedDocument(id: id, pages: pages.map { $0.page() }, isSparse: isSparse)
    }
}

struct StoredPage: Codable {
    var index: Int
    var text: String

    init(_ page: RecognizedPage) {
        index = page.index
        text = page.text
    }

    func page() -> RecognizedPage {
        RecognizedPage(index: index, text: text)
    }
}

struct StoredItem: Codable {
    var id: UUID
    var title: String
    var plainExplanation: String
    var quote: String
    var pageIndex: Int
    var severity: String

    init(_ item: ChecklistItem) {
        id = item.id
        title = item.title
        plainExplanation = item.plainExplanation
        quote = item.quote
        pageIndex = item.pageIndex
        severity = item.severity == .ok ? "ok" : "check"
    }

    func item() -> ChecklistItem {
        ChecklistItem(
            id: id,
            title: title,
            plainExplanation: plainExplanation,
            quote: quote,
            pageIndex: pageIndex,
            severity: ChecklistSeverity.resolved(from: severity)
        )
    }
}

struct StoredChecklist: Codable {
    var parties: [StoredItem]
    var money: [StoredItem]
    var dates: [StoredItem]
    var obligations: [StoredItem]
    var questionsBeforeSigning: [StoredItem]

    init(_ checklist: LeaseChecklist) {
        parties = checklist.parties.map(StoredItem.init)
        money = checklist.money.map(StoredItem.init)
        dates = checklist.dates.map(StoredItem.init)
        obligations = checklist.obligations.map(StoredItem.init)
        questionsBeforeSigning = checklist.questionsBeforeSigning.map(StoredItem.init)
    }

    func checklist() -> LeaseChecklist {
        LeaseChecklist(
            parties: parties.map { $0.item() },
            money: money.map { $0.item() },
            dates: dates.map { $0.item() },
            obligations: obligations.map { $0.item() },
            questionsBeforeSigning: questionsBeforeSigning.map { $0.item() }
        )
    }
}

struct StoredOutcome: Codable {
    var kind: String
    var checklist: StoredChecklist?
    var fallback: String?

    init(_ outcome: LeaseReading.Outcome) {
        switch outcome {
        case .checklist(let checklist):
            kind = "checklist"
            self.checklist = StoredChecklist(checklist)
            fallback = nil
        case .fallback(let reason):
            kind = "fallback"
            checklist = nil
            fallback = reason.storageKey
        }
    }

    func resolved() -> LeaseReading.Outcome? {
        switch kind {
        case "checklist":
            guard let checklist else { return nil }
            return .checklist(checklist.checklist())
        case "fallback":
            guard let fallback, let reason = FallbackReason(storageKey: fallback) else { return nil }
            return .fallback(reason)
        default:
            return nil
        }
    }
}

extension FallbackReason {
    var storageKey: String {
        switch self {
        case .sparseText: "sparseText"
        case .modelUnavailable: "modelUnavailable"
        case .modelNotReady: "modelNotReady"
        case .modelRefused: "modelRefused"
        case .contextExceeded: "contextExceeded"
        case .emptyModelAnswer: "emptyModelAnswer"
        case .modelFailed: "modelFailed"
        }
    }

    init?(storageKey: String) {
        switch storageKey {
        case "sparseText": self = .sparseText
        case "modelUnavailable": self = .modelUnavailable
        case "modelNotReady": self = .modelNotReady
        case "modelRefused": self = .modelRefused
        case "contextExceeded": self = .contextExceeded
        case "emptyModelAnswer": self = .emptyModelAnswer
        case "modelFailed": self = .modelFailed
        default: return nil
        }
    }
}
