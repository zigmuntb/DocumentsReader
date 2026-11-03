import Foundation

enum PagePayload: Equatable, Sendable {
    case image(Data)
    /// A PDF or image copied into our temporary directory while the security scope was open.
    case file(URL)
}
