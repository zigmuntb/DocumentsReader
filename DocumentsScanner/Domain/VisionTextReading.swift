import Foundation

protocol VisionTextReading: Sendable {
    func recognizeText(in imageData: Data) async throws -> VisionPage
}
