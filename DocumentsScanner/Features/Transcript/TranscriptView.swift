import Foundation
import SwiftUI

struct TranscriptView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: TranscriptViewModel

    var body: some View {
        DSScreen {
            switch viewModel.state {
            case .missing:
                missing
                    .transition(.opacity)
            case .loaded(let content):
                loaded(content)
                    .transition(.opacity)
            }
        }
        .dsReplaces(viewModel.state, reduceMotion: reduceMotion)
        .navigationTitle(String(localized: "Recognized text"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var missing: some View {
        Text(String(localized: "This reading is no longer on the device."))
            .font(DSFont.body)
            .foregroundStyle(DSColor.inkSecondary)
            .padding(DSSpacing.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func loaded(_ content: TranscriptContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.l) {
                if let fallback = content.fallback {
                    notice(FallbackCopy.message(for: fallback))
                    SigningQuestionsView()
                } else if content.document.isSparse {
                    notice(String(localized: "Only a little text was found. A checklist needs more of the lease than this."))
                }
                ForEach(content.document.pages) { page in
                    pageCard(page)
                }
            }
            .padding(DSSpacing.l)
        }
    }

    private func notice(_ message: String) -> some View {
        DSCard {
            Text(message)
                .font(DSFont.body)
                .foregroundStyle(DSColor.ink)
        }
    }

    private func pageCard(_ page: RecognizedPage) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.s) {
                Text(String(localized: "Page \(page.index + 1)"))
                    .font(DSFont.eyebrow)
                    .tracking(DSFont.eyebrowTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(DSColor.secondary)
                    .accessibilityAddTraits(.isHeader)
                Text(page.text.isEmpty ? String(localized: "No text on this page.") : page.text)
                    .font(DSFont.body)
                    .foregroundStyle(page.text.isEmpty ? DSColor.inkSecondary : DSColor.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview("Pages") {
    SampleTranscript()
}

private struct SampleTranscript: View {
    private let viewModel: TranscriptViewModel

    init() {
        let store = InMemoryDocumentSessionStore()
        let document = RecognizedDocument(
            id: UUID(),
            pages: [
                RecognizedPage(
                    index: 0,
                    text: "Tenant shall pay rent of $1,500 on the first day of each month."
                ),
                RecognizedPage(index: 1, text: "The term begins October 1, 2025 and ends September 30, 2026.")
            ],
            isSparse: false
        )
        store.save(document)
        viewModel = TranscriptViewModel(documentID: document.id, session: store)
    }

    var body: some View {
        NavigationStack {
            TranscriptView(viewModel: viewModel)
        }
    }
}
