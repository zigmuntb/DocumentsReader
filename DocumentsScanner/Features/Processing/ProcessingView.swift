import Foundation
import SwiftUI
import UIKit

struct ProcessingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: ProcessingViewModel

    var body: some View {
        DSScreen {
            Group {
                switch viewModel.phase {
                case .failed(let failure):
                    ScrollView {
                        failed(failure)
                            .padding(DSSpacing.l)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                default:
                    live(viewModel.phase)
                        .transition(.opacity)
                }
            }
            .dsReplaces(viewModel.phase, reduceMotion: reduceMotion)
        }
        .navigationTitle(headline(viewModel.phase))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.phase) { previous, phase in
            guard announcementKind(previous) != announcementKind(phase) else { return }
            AccessibilityNotification.Announcement(announcement(phase)).post()
        }
        .onChange(of: viewModel.livePage?.pageIndex) { _, _ in
            guard let page = viewModel.livePage, page.pageCount > 0 else { return }
            let message = String(localized: "Page \(page.pageIndex + 1) of \(page.pageCount)")
            AccessibilityNotification.Announcement(message).post()
        }
        .task { await viewModel.run(reduceMotion: reduceMotion) }
    }

    private func live(_ phase: ProcessingPhase) -> some View {
        ScanStageView(frame: viewModel.livePage, reduceMotion: reduceMotion)
            .padding(.horizontal, DSSpacing.l)
            .padding(.top, DSSpacing.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: DSSpacing.m) {
                progress(phase)
                    .padding(.horizontal, DSSpacing.l)
                    .padding(.bottom, DSSpacing.s)
                    .frame(maxWidth: .infinity)
                    .background(DSColor.paper)
            }
    }

    private func progress(_ phase: ProcessingPhase) -> some View {
        let completed = phase.completed
        let total = phase.total
        return VStack(spacing: DSSpacing.s) {
            if total > 0 {
                ProgressView(value: Double(completed), total: Double(total))
                    .tint(DSColor.primary)
                    .frame(maxWidth: DSSpacing.xxl * 4)
            } else if isChecking(phase) {
                ProgressView()
                    .controlSize(.large)
                    .tint(DSColor.primary)
            }
            Text(headline(phase))
                .font(DSFont.title)
                .foregroundStyle(DSColor.ink)
                .multilineTextAlignment(.center)
            if let detail = detail(completed: completed, total: total, phase: phase) {
                Text(detail)
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
                Task { await viewModel.run(reduceMotion: reduceMotion) }
            }
        }
    }

    private func headline(_ phase: ProcessingPhase) -> String {
        if isChecking(phase) {
            return String(localized: "Checking the lease")
        }
        return String(localized: "Reading the lease")
    }

    private func isChecking(_ phase: ProcessingPhase) -> Bool {
        if case .checking = phase { return true }
        return false
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

    private func detail(completed: Int, total: Int, phase: ProcessingPhase) -> String? {
        if isChecking(phase) {
            guard total > 0 else { return nil }
            return String(localized: "Part \(completed) of \(total)")
        }
        if let page = viewModel.livePage, page.pageCount > 0 {
            return String(localized: "Page \(page.pageIndex + 1) of \(page.pageCount)")
        }
        guard total > 0 else { return nil }
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
        onPage: @escaping @Sendable (ScanFrame) -> Void
    ) async throws -> [RecognizedPage] {
        let image = SampleLeasePage.jpeg()
        onPage(ScanFrame(
            pageIndex: 0,
            pageCount: 1,
            imageJPEG: image,
            lines: [],
            activity: .sweeping
        ))
        try await Task.sleep(for: .seconds(1.2))
        onPage(ScanFrame(
            pageIndex: 0,
            pageCount: 1,
            imageJPEG: image,
            lines: SampleLeasePage.lines(),
            activity: .readingLines
        ))
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

private enum SampleLeasePage {
    static let rows = [
        "Residential lease",
        "Tenant shall pay rent of $1,500.",
        "Rent is due on the first of the month.",
        "The term is twelve months."
    ]

    static func jpeg() -> Data {
        let size = CGSize(width: 400, height: 560)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.black
            ]
            for (index, line) in rows.enumerated() {
                let rect = CGRect(x: 36, y: 48 + CGFloat(index) * 36, width: 328, height: 24)
                (line as NSString).draw(in: rect, withAttributes: attributes)
            }
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }

    static func lines() -> [ScanLine] {
        rows.enumerated().map { index, text in
            let y = (48 + CGFloat(index) * 36) / 560
            return ScanLine(
                index: index,
                text: text,
                bounds: CGRect(x: 36.0 / 400.0, y: y, width: 328.0 / 400.0, height: 24.0 / 560.0)
            )
        }
    }
}
