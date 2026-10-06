//
//  DataScannerRepresentable.swift
//  KindDose
//

import SwiftUI
import VisionKit

/// Bridges VisionKit's live text scanner into SwiftUI, reporting every recognized
/// line of text back as a plain string so the host view can let the person pick
/// which lines are the name and dose.
struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var recognizedLines: [String]

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedLines: $recognizedLines)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedLines: [String]

        init(recognizedLines: Binding<[String]>) {
            _recognizedLines = recognizedLines
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateLines(from: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateLines(from: allItems)
        }

        private func updateLines(from items: [RecognizedItem]) {
            let lines: [String] = items.compactMap { item in
                guard case let .text(text) = item else { return nil }
                return text.transcript
            }
            DispatchQueue.main.async {
                self.recognizedLines = lines
            }
        }
    }
}
