import Foundation

protocol ChecklistGenerating: Sendable {
    func generate(from prompt: String) async throws -> LeaseChecklist
}
