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

                // Separate observations into equation lines and potential answer candidates
                struct TextItem {
                    let text: String
                    let box: CGRect // Vision normalized coordinates
                }

                var equationLines: [TextItem] = []
                var answerCandidates: [TextItem] = []

                for observation in results {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let item = TextItem(text: candidate.string, box: observation.boundingBox)

                    if candidate.string.contains("=") || candidate.string.contains("+")
                        || candidate.string.contains("-") || candidate.string.contains("×")
                        || candidate.string.contains("÷") {
                        equationLines.append(item)
                    } else {
                        // Check if it looks like a number (digits, possibly with minus)
                        let cleaned = candidate.string.trimmingCharacters(in: .whitespaces)
                        let digits = cleaned.filter { $0.isNumber || $0 == "-" }
                        if !digits.isEmpty, Int(digits) != nil {
                            answerCandidates.append(item)
                        }
                    }
                }

                // Sort equation lines top to bottom (highest y first in Vision coords)
                equationLines.sort { $0.box.midY > $1.box.midY }

                // For each equation line, find the best matching answer candidate:
                // - Similar vertical position (within tolerance)
                // - To the right of the equation (higher minX)
                var answers: [Int?] = []
                var usedCandidates: Set<Int> = []

                for eqLine in equationLines {
                    var bestMatch: Int? = nil
                    var bestDistance: CGFloat = .greatestFiniteMagnitude

                    for (idx, candidate) in answerCandidates.enumerated() {
                        if usedCandidates.contains(idx) { continue }

                        // Must be at roughly the same vertical level (within 5% of page height)
                        let yDistance = abs(candidate.box.midY - eqLine.box.midY)
                        if yDistance > 0.05 { continue }

                        // Prefer candidates to the right of the equation
                        let xDistance = candidate.box.minX - eqLine.box.maxX
                        // Allow some overlap but prefer rightward
                        if xDistance < -0.1 { continue }

                        let totalDistance = yDistance + abs(xDistance) * 0.5
                        if totalDistance < bestDistance {
                            bestDistance = totalDistance
                            bestMatch = idx
                        }
                    }

                    if let matchIdx = bestMatch {
                        usedCandidates.insert(matchIdx)
                        let digits = answerCandidates[matchIdx].text
                            .trimmingCharacters(in: .whitespaces)
                            .filter { $0.isNumber || $0 == "-" }
                        answers.append(Int(digits))
                    } else {
                        // Also try: answer might be part of the equation line text (after "=")
                        if let eqRange = eqLine.text.range(of: "=") {
                            let afterEq = eqLine.text[eqRange.upperBound...]
                                .trimmingCharacters(in: .whitespaces)
                            let digits = afterEq.filter { $0.isNumber || $0 == "-" }
                            if let num = Int(digits), !digits.isEmpty {
                                answers.append(num)
                            } else {
                                answers.append(nil)
                            }
                        } else {
                            answers.append(nil)
                        }
                    }
                }

                // Pad with nils if we didn't find enough equations
                while answers.count < expectedCount {
                    answers.append(nil)
                }

                continuation.resume(returning: Array(answers.prefix(expectedCount)))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.customWords = ["-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
