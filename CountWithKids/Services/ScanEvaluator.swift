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

    private static func recognizeAnswers(from cgImage: CGImage, expectedCount: Int) async -> [Int?] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: Array(repeating: nil, count: expectedCount))
                    return
                }

                // Collect all recognized text with their vertical positions
                var textItems: [(text: String, y: CGFloat)] = []
                for observation in results {
                    if let candidate = observation.topCandidates(1).first {
                        // In Vision coordinates, y=0 is bottom, y=1 is top
                        let midY = observation.boundingBox.midY
                        textItems.append((candidate.string, midY))
                    }
                }

                // Sort top to bottom (highest y first in Vision coordinates)
                textItems.sort { $0.y > $1.y }

                // Look for answers after "=" signs
                var answers: [Int?] = []
                for item in textItems {
                    let text = item.text
                    // Look for patterns like "5 + 3 = 8" or just standalone numbers after equation lines
                    if let eqRange = text.range(of: "=") {
                        let afterEq = text[eqRange.upperBound...].trimmingCharacters(in: .whitespaces)
                        if let num = Int(afterEq.filter { $0.isNumber || $0 == "-" }) {
                            answers.append(num)
                        }
                    }
                }

                // Pad with nils if we didn't find enough
                while answers.count < expectedCount {
                    answers.append(nil)
                }

                continuation.resume(returning: Array(answers.prefix(expectedCount)))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            // Recognize digits and math symbols
            request.customWords = ["-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
