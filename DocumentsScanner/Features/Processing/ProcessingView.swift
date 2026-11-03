import Foundation
import SwiftUI

struct ProcessingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: ProcessingViewModel

    var body: some View {
        DSScreen {
            ScrollView {
                VStack(spacing: DSSpacing.l) {
                    switch viewModel.phase {
                    case .idle, .reading, .checking:
                        progress(viewModel.phase)
                            .transition(.opacity)
                    case .failed(let failure):
                        failed(failure)
                            .transition(.opacity)
                    }
                }
                .dsReplaces(viewModel.phase, reduceMotion: reduceMotion)
                .padding(DSSpacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(headline(viewModel.phase))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.phase) { previous, phase in
            guard announcementKind(previous) != announcementKind(phase) else { return }
            AccessibilityNotification.Announcement(announcement(phase)).post()
        }
        .task { await viewModel.run() }
    }

    private func progress(_ phase: ProcessingPhase) -> some View {
        let completed = phase.completed
        let total = phase.total
        return VStack(spacing: DSSpacing.l) {
            if total > 0 {
                ProgressView(value: Double(completed), total: Double(total))
                    .tint(DSColor.primary)
                    .frame(maxWidth: DSSpacing.xxl * 4)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(DSColor.primary)
            }
            Text(headline(phase))
                .font(DSFont.title)
                .foregroundStyle(DSColor.ink)
                .multilineTextAlignment(.center)
            if total > 0 {
                Text(detail(completed: completed, total: total, phase: phase))
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func failed(_ failure: ProcessingFailure) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.l) {
            Text(failure.message)
                .font(DSFont.body)
                .foregroundStyle(DSColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            DSButton(title: String(localized: "Try again"), style: .primary) {
                Task { await viewModel.run() }
            }
        }
    }

    private func headline(_ phase: ProcessingPhase) -> String {
        if case .checking = phase {
            return String(localized: "Checking the lease")
        }
        return String(localized: "Reading the lease")
    }

    private func announcement(_ phase: ProcessingPhase) -> String {
        if case .failed(let failure) = phase {
            return failure.message
        }
        return headline(phase)
    }

    private func announcementKind(_ phase: ProcessingPhase) -> String {
        switch phase {
        case .idle, .reading:
            "reading"
        case .checking:
            "checking"
        case .failed:
            "failed"
        }
    }

    private func detail(completed: Int, total: Int, phase: ProcessingPhase) -> String {
        if case .checking = phase {
            return String(localized: "Part \(completed) of \(total)")
        }
        return String(localized: "Page \(completed) of \(total)")
    }
}

private extension ProcessingPhase {
    var completed: Int {
        switch self {
        case .reading(let completed, _), .checking(let completed, _):
            completed
        case .idle, .failed:
            0
        }
    }

    var total: Int {
        switch self {
        case .reading(_, let total), .checking(_, let total):
            total
        case .idle, .failed:
            0
        }
    }
}

#Preview {
    ProcessingPreview()
}

private struct ProcessingPreview: View {
    private let viewModel: ProcessingViewModel

    init() {
        let store = InMemoryDocumentSessionStore()
        let id = store.stage(.pages([.image(Data([0]))]))
        viewModel = ProcessingViewModel(
            documentID: id,
            session: store,
            recognizer: HoldingTextRecognizer(),
            analyzer: HoldingAnalyzer()
        )
    }

    var body: some View {
        NavigationStack {
            ProcessingView(viewModel: viewModel)
        }
    }
}

private struct HoldingTextRecognizer: TextRecognizing {
    func recognize(
        _ job: RecognitionJob,
        onPage: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> [RecognizedPage] {
        onPage(0, 1)
        try await Task.sleep(for: .seconds(60))
        return []
    }
}

private struct HoldingAnalyzer: LeaseAnalyzing {
    func analyze(
        _ document: RecognizedDocument,
        onChunk: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> LeaseReading {
        try await Task.sleep(for: .seconds(60))
        return LeaseReading(document: document, outcome: .fallback(.modelUnavailable))
    }
}
