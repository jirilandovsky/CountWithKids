import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    let onScanCompleted: ([UIImage]) -> Void
    let onCancelled: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanCompleted: onScanCompleted, onCancelled: onCancelled)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanCompleted: ([UIImage]) -> Void
        let onCancelled: () -> Void

        init(onScanCompleted: @escaping ([UIImage]) -> Void, onCancelled: @escaping () -> Void) {
            self.onScanCompleted = onScanCompleted
            self.onCancelled = onCancelled
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            controller.dismiss(animated: true) {
                self.onScanCompleted(images)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.onCancelled()
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) {
                self.onCancelled()
            }
        }
    }
}
