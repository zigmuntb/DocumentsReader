import SwiftUI
import UIKit
import VisionKit

/// The camera callback is already on the main thread. JPEG encoding happens here so image orientation survives the handoff.
struct DocumentCameraView: UIViewControllerRepresentable {
    let onScan: ([Data]) -> Void
    let onCancel: () -> Void
    let onFail: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel, onFail: onFail)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([Data]) -> Void
        let onCancel: () -> Void
        let onFail: () -> Void

        init(
            onScan: @escaping ([Data]) -> Void,
            onCancel: @escaping () -> Void,
            onFail: @escaping () -> Void
        ) {
            self.onScan = onScan
            self.onCancel = onCancel
            self.onFail = onFail
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onFail()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var pages: [Data] = []
            for index in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: index)
                if let data = image.jpegData(compressionQuality: 0.82) {
                    pages.append(data)
                }
            }
            onScan(pages)
        }
    }
}
