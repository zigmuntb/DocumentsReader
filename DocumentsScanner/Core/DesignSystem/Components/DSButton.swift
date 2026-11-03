import SwiftUI

struct DSButton: View {
    enum Style {
        case primary
        case secondary
        case inverted
        case outlined
    }

    let title: String
    var style: Style = .primary
    var fillsWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(DSButtonStyle(style: style, fillsWidth: fillsWidth))
    }
}

private struct DSButtonStyle: ButtonStyle {
    let style: DSButton.Style
    let fillsWidth: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSFont.label)
            .multilineTextAlignment(.center)
            .foregroundStyle(foreground)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: DSSpacing.touch)
            .padding(.horizontal, DSSpacing.m)
            .background(background, in: shape)
            .overlay {
                if showsBorder {
                    shape.strokeBorder(borderColor, lineWidth: 1)
                }
            }
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DSRadius.m, style: .continuous)
    }

    private var foreground: Color {
        switch style {
        case .primary:
            DSColor.onPrimary
        case .secondary, .outlined:
            DSColor.ink
        case .inverted:
            DSColor.onInverted
        }
    }

    private var background: Color {
        switch style {
        case .primary:
            DSColor.primary
        case .secondary:
            DSColor.surface
        case .inverted:
            DSColor.inverted
        case .outlined:
            DSColor.paper
        }
    }

    private var showsBorder: Bool {
        switch style {
        case .secondary, .outlined:
            true
        case .primary, .inverted:
            false
        }
    }

    private var borderColor: Color {
        style == .outlined ? DSColor.inkSecondary : DSColor.hairline
    }
}

#Preview("Styles") {
    DSScreen {
        VStack(spacing: DSSpacing.s) {
            DSButton(title: "Scan a lease", style: .primary) {}
            DSButton(title: "Secondary", style: .secondary) {}
            DSButton(title: "Inverted", style: .inverted) {}
            DSButton(title: "Outlined", style: .outlined) {}
        }
        .padding(DSSpacing.l)
    }
}

#Preview("Dark") {
    DSScreen {
        VStack(spacing: DSSpacing.s) {
            DSButton(title: "Scan a lease", style: .primary) {}
            DSButton(title: "Outlined", style: .outlined) {}
        }
        .padding(DSSpacing.l)
    }
    .preferredColorScheme(.dark)
}
