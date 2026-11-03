import Foundation

struct LeaseHistoryEntry: Equatable, Sendable, Identifiable {
    let id: UUID
    let createdAt: Date
    /// The first line of the recognized text, shortened. Nil when the lease has no text to name.
    let title: String?
    let summary: Summary

    enum Summary: Equatable, Sendable {
        case checklist(itemCount: Int)
        case textOnly
    }

    static func make(reading: LeaseReading, createdAt: Date) -> LeaseHistoryEntry {
        LeaseHistoryEntry(
            id: reading.document.id,
            createdAt: createdAt,
            title: title(from: reading.document),
            summary: summary(for: reading.outcome)
        )
    }

    private static func title(from document: RecognizedDocument) -> String? {
        let line = document.pages
            .lazy
            .flatMap { $0.text.split(whereSeparator: \.isNewline) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        guard let line else { return nil }
        if line.count <= maximumTitleLength { return String(line) }
        let end = line.index(line.startIndex, offsetBy: maximumTitleLength - 3)
        return String(line[..<end]) + "..."
    }

    private static func summary(for outcome: LeaseReading.Outcome) -> Summary {
        switch outcome {
        case .checklist(let checklist):
            .checklist(itemCount: checklist.parties.count
                + checklist.money.count
                + checklist.dates.count
                + checklist.obligations.count
                + checklist.questionsBeforeSigning.count)
        case .fallback:
            .textOnly
        }
    }

    private static let maximumTitleLength = 80
}
