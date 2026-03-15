import UIKit
import Vision

struct ScanEvaluator {

    struct EvaluatedProblem: Identifiable {
        let id = UUID()
        let problem: MathProblem
        let detectedAnswer: Int?
        var userAnswer: String

        var isCorrect: Bool {
            guard let answer = Int(userAnswer) else { return false }
            return answer == problem.correctAnswer
        }
    }

    /// Process scanned images: decode QR code for problems, OCR for answers
    static func evaluate(images: [UIImage]) async -> (problems: [MathProblem], detectedAnswers: [Int?])? {
        guard let firstImage = images.first,
              let cgImage = firstImage.cgImage else {
            return nil
        }

        // Step 1: Find and decode QR code
        guard let problems = await decodeQRCode(from: cgImage) else {
            return nil
        }

        // Step 2: OCR to find handwritten answers
        let answers = await recognizeAnswers(from: cgImage, expectedCount: problems.count)

        return (problems, answers)
    }

    private static func decodeQRCode(from cgImage: CGImage) async -> [MathProblem]? {
        await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                for barcode in results {
                    if barcode.symbology == .qr,
                       let payload = barcode.payloadStringValue,
                       let data = payload.data(using: .utf8),
                       let problems = PrintablePageRenderer.decodeProblems(from: data) {
                        continuation.resume(returning: problems)
                        return
                    }
                }
                continuation.resume(returning: nil)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// Recognize answer for a single problem by cropping the known answer box region
    private static func recognizeAnswerInRegion(cgImage: CGImage, index: Int) async -> Int? {
        // Get the normalized answer box position from the print layout
        let normBox = PrintablePageRenderer.answerBoxNormalized(index: index)

        // Convert from PDF coordinates (origin top-left) to Vision coordinates (origin bottom-left)
        // Also add padding around the box to catch handwriting that extends outside
        let padding: CGFloat = 0.03
        let visionRect = CGRect(
            x: max(0, normBox.minX - padding),
            y: max(0, 1.0 - normBox.maxY - padding),
            width: min(1.0, normBox.width + padding * 2),
            height: min(1.0, normBox.height + padding * 2)
        )

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Find the best number candidate in this region
                for observation in results {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let cleaned = candidate.string.trimmingCharacters(in: .whitespaces)
                    let digits = cleaned.filter { $0.isNumber || $0 == "-" }
                    if !digits.isEmpty, let num = Int(digits) {
                        continuation.resume(returning: num)
                        return
                    }
                }
                continuation.resume(returning: nil)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.customWords = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
            request.regionOfInterest = visionRect

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private static func recognizeAnswers(from cgImage: CGImage, expectedCount: Int) async -> [Int?] {
        var answers: [Int?] = []
        for index in 0..<expectedCount {
            let answer = await recognizeAnswerInRegion(cgImage: cgImage, index: index)
            answers.append(answer)
        }
        return answers
    }
}
