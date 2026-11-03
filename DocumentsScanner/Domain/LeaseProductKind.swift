import Foundation

enum LeaseProductKind: String, CaseIterable, Equatable, Sendable, Identifiable {
    case yearly
    case lifetime

    var id: String { rawValue }

    /// TODO: create these in App Store Connect. Yearly is $29.99 with no trial. Lifetime is $49.99. There is no weekly product.
    var productID: String {
        switch self {
        case .yearly:
            "com.BogdanArsenkin.DocumentsScanner.pro.yearly"
        case .lifetime:
            "com.BogdanArsenkin.DocumentsScanner.pro.lifetime"
        }
    }
}
