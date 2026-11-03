import SwiftUI
import VisionKit

struct ScanView: View {
    let viewModel: ScanViewModel

    var body: some View {
        DocumentCameraView(
            onScan: { pages in
                viewModel.didScan(pages: pages)
            },
            onCancel: {
                viewModel.cancel()
            },
            onFail: {
                viewModel.didScan(pages: [])
            }
        )
        .ignoresSafeArea()
    }
}
