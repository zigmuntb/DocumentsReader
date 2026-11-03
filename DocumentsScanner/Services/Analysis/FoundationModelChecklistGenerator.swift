import Foundation
import FoundationModels

struct FoundationModelChecklistGenerator: ChecklistGenerating {
    func generate(from prompt: String) async throws -> LeaseChecklist {
        // A new session per excerpt keeps earlier chunks out of the 4096-token window.
        // Temperature stays low so the wording stays close to that excerpt.
        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let response = try await session.respond(
                to: prompt,
                generating: GeneratedChecklist.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(temperature: 0.2)
            )
            return Self.checklist(from: response.content)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ModelFailureMapper.classify(error)
        }
    }

    private static let instructions = """
    Extract only facts that the excerpt states. Copy each quote verbatim from the excerpt.
    Use short, plain sentences. Do not give legal advice, opinions, or recommendations.
    If the excerpt does not state a fact, leave that list empty.
    severity is ok for an ordinary term and check when the term is unusual or one-sided.
    pageIndex is the page index printed in the excerpt.
    """

    private static func checklist(from generated: GeneratedChecklist) -> LeaseChecklist {
        LeaseChecklist(
            parties: items(from: generated.parties),
            money: items(from: generated.money),
            dates: items(from: generated.dates),
            obligations: items(from: generated.obligations),
            questionsBeforeSigning: items(from: generated.questionsBeforeSigning)
        )
    }

    private static func items(from generated: [GeneratedChecklistItem]) -> [ChecklistItem] {
        generated.map { item in
            ChecklistItem(
                id: UUID(),
                title: item.title,
                plainExplanation: item.plainExplanation,
                quote: item.quote,
                pageIndex: item.pageIndex,
                severity: ChecklistSeverity.resolved(from: item.severity)
            )
        }
    }
}
