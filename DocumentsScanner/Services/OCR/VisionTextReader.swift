import Foundation
import ImageIO
import Vision

struct VisionTextReader: VisionTextReading {
    func recognizeText(in imageData: Data) async throws -> String {
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw DocumentReadError.unreadableFile
        }

        let gate = ResumeGate()
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    gate.resume(continuation, with: .failure(error))
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.sorted { lhs, rhs in
                    let deltaY = lhs.boundingBox.midY - rhs.boundingBox.midY
                    if abs(deltaY) > 0.015 {
                        return lhs.boundingBox.midY > rhs.boundingBox.midY
                    }
                    return lhs.boundingBox.minX < rhs.boundingBox.minX
                }
                let text = lines.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                gate.resume(continuation, with: .success(text))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true

            do {
                try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
            } catch {
                gate.resume(continuation, with: .failure(error))
            }
        }
    }
}

/// `perform` can throw after the request handler has already resumed the continuation.
private final class ResumeGate: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false

    func resume(_ continuation: CheckedContinuation<String, Error>, with result: Result<String, Error>) {
        lock.lock()
        let shouldResume = !didResume
        didResume = true
        lock.unlock()
        guard shouldResume else { return }
        continuation.resume(with: result)
    }
}
