import SwiftUI
import UIKit

/// Light values are sampled from the Editorial Legal Audit board.
/// The board has no dark frames, so the dark values are derived. Text on these backgrounds clears WCAG AA.
/// Increase Contrast strengthens secondary text and hairlines.
enum DSColor {
    static let paper = dynamic(light: 0xFBF7EF, dark: 0x1C1C17)
    static let surface = dynamic(light: 0xF4F0E8, dark: 0x31312C)
    static let elevated = dynamic(light: 0xFFFFFF, dark: 0x484742)
    static let ink = dynamic(light: 0x1C1C17, dark: 0xFBF7EF)
    static let inkSecondary = dynamic(
        light: 0x605E59,
        dark: 0xC9C6BF,
        lightIncreased: 0x3F3D39,
        darkIncreased: 0xE7E4DC
    )
    static let primary = dynamic(light: 0xAA3A2E, dark: 0xE76655)
    static let onPrimary = dynamic(light: 0xFBF7EF, dark: 0x1C1C17)
    static let secondary = dynamic(light: 0x415D3C, dark: 0x95B58C)
    static let tertiary = dynamic(light: 0xF1E8AF, dark: 0x988B53)
    static let quote = dynamic(light: 0xF1E8AF, dark: 0x4D4720)
    static let hairline = dynamic(
        light: 0xE6E2DA,
        dark: 0x484742,
        lightIncreased: 0x76726C,
        darkIncreased: 0x9C9890
    )
    static let inverted = dynamic(light: 0x1C1C17, dark: 0xFBF7EF)
    static let onInverted = dynamic(light: 0xFBF7EF, dark: 0x1C1C17)

    private static func dynamic(
        light: UInt32,
        dark: UInt32,
        lightIncreased: UInt32? = nil,
        darkIncreased: UInt32? = nil
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let increased = traits.accessibilityContrast == .high
            if traits.userInterfaceStyle == .dark {
                return uiColor(hex: increased ? (darkIncreased ?? dark) : dark)
            }
            return uiColor(hex: increased ? (lightIncreased ?? light) : light)
        })
    }
}

private func uiColor(hex: UInt32) -> UIColor {
    let red = CGFloat((hex >> 16) & 0xFF) / 255
    let green = CGFloat((hex >> 8) & 0xFF) / 255
    let blue = CGFloat(hex & 0xFF) / 255
    return UIColor(red: red, green: green, blue: blue, alpha: 1)
}
