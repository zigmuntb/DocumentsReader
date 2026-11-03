import Foundation

struct LeaseOffering: Equatable, Sendable, Identifiable {
    let kind: LeaseProductKind
    let displayPrice: String

    var id: LeaseProductKind { kind }
}
