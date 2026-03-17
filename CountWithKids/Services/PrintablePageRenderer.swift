import UIKit
import CoreImage.CIFilterBuiltins

struct PrintablePageRenderer {
    let problems: [MathProblem]
    let settings: AppSettings
    let title: String

    // Fixed layout constants
    static let answerBoxWidth: CGFloat = 80
    static let answerBoxHeight: CGFloat = 36
    static let pageWidth: CGFloat = 595       // A4
    static let pageHeight: CGFloat = 842
    static let margin: CGFloat = 50
    static let problemTextX: CGFloat = 90     // margin(50) + number column(40)
    static let headerHeight: CGFloat = 90     // title + subtitle + separator
    static let lineHeight: CGFloat = 50
    static let answerBoxGap: CGFloat = 10     // gap between "=" and the answer box

    /// Compute the X position for answer boxes based on the widest equation
    func answerBoxX() -> CGFloat {
        let problemFont = UIFont.systemFont(ofSize: 24, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: problemFont]
        let maxWidth = problems.map { ($0.displayString as NSString).size(withAttributes: attrs).width }.max() ?? 100
        return Self.problemTextX + maxWidth + Self.answerBoxGap
    }

    /// Returns normalized rect (0–1) for the answer box of problem at given index
    func answerBoxNormalized(index: Int) -> CGRect {
        let boxX = answerBoxX()
        let y = Self.margin + Self.headerHeight + CGFloat(index) * Self.lineHeight + 7
        return CGRect(
            x: boxX / Self.pageWidth,
            y: y / Self.pageHeight,
            width: Self.answerBoxWidth / Self.pageWidth,
            height: Self.answerBoxHeight / Self.pageHeight
        )
    }

    func generatePDF() -> Data {
        let pageWidth = Self.pageWidth
        let pageHeight = Self.pageHeight
        let margin = Self.margin
        let lineHeight = Self.lineHeight

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()

            var y = margin

            // Title
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            let titleStr = title as NSString
            let titleSize = titleStr.size(withAttributes: titleAttrs)
            titleStr.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += titleSize.height + 8

            // Subtitle: difficulty + date
            let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [.font: subtitleFont, .foregroundColor: UIColor.darkGray]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let subtitle = "\(settings.difficultyDisplayName)  •  \(dateFormatter.string(from: Date()))"
            (subtitle as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttrs)
            y += 30

            // Separator
            let separatorPath = UIBezierPath()
            separatorPath.move(to: CGPoint(x: margin, y: y))
            separatorPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.lightGray.setStroke()
            separatorPath.lineWidth = 0.5
            separatorPath.stroke()
            y += 20

            // Problems
            let problemFont = UIFont.systemFont(ofSize: 24, weight: .medium)
            let numberFont = UIFont.systemFont(ofSize: 18, weight: .regular)
            let problemAttrs: [NSAttributedString.Key: Any] = [.font: problemFont, .foregroundColor: UIColor.black]
            let numberAttrs: [NSAttributedString.Key: Any] = [.font: numberFont, .foregroundColor: UIColor.gray]

            for (index, problem) in problems.enumerated() {
                let numberStr = "\(index + 1)."
                (numberStr as NSString).draw(at: CGPoint(x: margin, y: y + 2), withAttributes: numberAttrs)

                let problemStr = problem.displayString
                (problemStr as NSString).draw(at: CGPoint(x: margin + 40, y: y), withAttributes: problemAttrs)

                // Answer box — rounded rectangle, positioned right after the equation
                let boxX = self.answerBoxX()
                let boxRect = CGRect(
                    x: boxX,
                    y: y + 7,
                    width: Self.answerBoxWidth,
                    height: Self.answerBoxHeight
                )
                let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 6)
                UIColor(white: 0.85, alpha: 1.0).setStroke()
                boxPath.lineWidth = 1.5
                boxPath.stroke()

                y += lineHeight
            }

            // QR code at bottom-right
            if let qrImage = generateQRCode() {
                let qrSize: CGFloat = 100
                let qrX = pageWidth - margin - qrSize
                let qrY = pageHeight - margin - qrSize
                qrImage.draw(in: CGRect(x: qrX, y: qrY, width: qrSize, height: qrSize))

                let qrLabel = loc("Scan to evaluate") as NSString
                let qrLabelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: UIColor.gray
                ]
                let labelSize = qrLabel.size(withAttributes: qrLabelAttrs)
                qrLabel.draw(at: CGPoint(x: qrX + (qrSize - labelSize.width) / 2, y: qrY - 14), withAttributes: qrLabelAttrs)
            }
        }
    }

    func generateQRCode() -> UIImage? {
        guard let jsonData = encodeProblems() else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = jsonData
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }
        let scale = 10.0
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let cgImage = CIContext().createCGImage(transformed, from: transformed.extent)
        return cgImage.map { UIImage(cgImage: $0) }
    }

    func encodeProblems() -> Data? {
        let encoded: [[String: Any]] = problems.map { p in
            ["a": p.operand1, "b": p.operand2, "op": p.operation.rawValue, "ans": p.correctAnswer]
        }
        // Encode box X as normalized value so scanner knows where answer boxes are
        let normBoxX = answerBoxX() / Self.pageWidth
        let payload: [String: Any] = ["v": 2, "p": encoded, "n": problems.count, "bx": Double(normBoxX)]
        return try? JSONSerialization.data(withJSONObject: payload)
    }

    struct DecodedPage {
        let problems: [MathProblem]
        let normalizedBoxX: CGFloat? // nil for v1 QR codes
    }

    static func decode(from data: Data) -> DecodedPage? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = json["v"] as? Int, (version == 1 || version == 2),
              let problemsArray = json["p"] as? [[String: Any]] else {
            return nil
        }

        let problems = problemsArray.compactMap { dict -> MathProblem? in
            guard let a = dict["a"] as? Int,
                  let b = dict["b"] as? Int,
                  let opStr = dict["op"] as? String,
                  let op = MathOperation(rawValue: opStr),
                  let ans = dict["ans"] as? Int else {
                return nil
            }
            return MathProblem(operand1: a, operand2: b, operation: op, correctAnswer: ans)
        }

        let boxX = (json["bx"] as? Double).map { CGFloat($0) }
        return DecodedPage(problems: problems, normalizedBoxX: boxX)
    }

    // Keep backward compat
    static func decodeProblems(from data: Data) -> [MathProblem]? {
        decode(from: data)?.problems
    }
}
