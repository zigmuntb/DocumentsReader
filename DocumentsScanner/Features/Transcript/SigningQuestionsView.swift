import SwiftUI

struct SigningQuestionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            Text(String(localized: "Questions to answer before you sign"))
                .font(DSFont.title)
                .foregroundStyle(DSColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text(String(localized: "These questions are a fixed list. They are not drawn from your lease."))
                .font(DSFont.body)
                .foregroundStyle(DSColor.inkSecondary)
            ForEach(Array(SigningQuestionTemplate.questions.enumerated()), id: \.offset) { _, question in
                DSCard {
                    Text(question)
                        .font(DSFont.body)
                        .foregroundStyle(DSColor.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
