import Foundation
import Vision

struct VisionTextReader: VisionTextReading {
    func recognizeText(in imageData: Data) async throws -> VisionPage {
        try Task.checkCancellation()
        return try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let image = try PageImageNormalizer.cgImage(from: imageData)
            let displayJPEG = try ImageJPEG.data(from: image)
            let lines = try Self.lines(in: image)
            return VisionPage(lines: lines, displayJPEG: displayJPEG)
        }.value
    }

    private static func lines(in image: CGImage) throws -> [ObservedTextLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        return (request.results ?? []).compactMap { observation in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            return ObservedTextLine(text: text, bounds: observation.boundingBox)
        }
    }
}
