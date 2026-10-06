//
//  ScanMedicineView.swift
//  KindDose
//

import SwiftUI
import SwiftData
import VisionKit
import Vision
import PhotosUI
import UIKit

/// Scans a pharmacy label, box, or handwritten list with VisionKit's live text
/// scanner. Falls back to taking or choosing a photo plus on-device Vision text
/// recognition where the live scanner isn't supported. Always ends on the
/// "Is this correct?" confirm screen — nothing is saved from here directly.
struct ScanMedicineView: View {
    @State private var recognizedLines: [String] = []
    @State private var nameLine: String?
    @State private var doseLine: String?
    @State private var capturedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCameraCapture = false
    @State private var goToConfirm = false

    private var dataScannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        ZStack {
            CalmBackground()

            if dataScannerAvailable {
                liveScannerContent
            } else {
                fallbackPhotoContent
            }
        }
        .navigationTitle("Scan a label")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $goToConfirm) {
            AddMedicineConfirmView(draft: finalDraft())
        }
    }

    // MARK: - Live scanner

    private var liveScannerContent: some View {
        // The camera view stays permanently in the same place in the tree so its
        // identity never changes — switching it between two different parent layouts
        // (e.g. a plain view vs. nested in a ScrollView) makes SwiftUI tear down and
        // recreate the live DataScannerViewController every time recognizedLines first
        // goes non-empty, which stalls the camera mid-scan. The panel is an overlay
        // instead, and scrolls internally so a long list of recognized lines (and the
        // Continue button below it) always stays reachable, even at the largest
        // Dynamic Type sizes.
        ZStack(alignment: .bottom) {
            DataScannerRepresentable(recognizedLines: $recognizedLines)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !recognizedLines.isEmpty {
                ScrollView {
                    recognizedLinesPanel
                        .padding(16)
                        .calmScreenWidth()
                }
                .frame(maxHeight: 420)
            }
        }
    }

    // MARK: - Fallback: camera or photo library + Vision

    private var fallbackPhotoContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Live scanning isn't available on this device. Take or choose a photo of the label instead.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .calmCard()

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take a photo") {
                        showCameraCapture = true
                    }
                    .buttonStyle(.bigButton)
                    .accessibilityHint("Opens your camera to photograph the label.")
                }

                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Text("Choose from Photos")
                }
                .buttonStyle(.bigButton)
                .accessibilityHint("Picks a photo of the label from your photo library.")

                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityHidden(true)
                }

                if !recognizedLines.isEmpty {
                    recognizedLinesPanel
                }
            }
            .padding(24)
            .calmScreenWidth()
        }
        .sheet(isPresented: $showCameraCapture) {
            CameraCaptureView { image in
                capturedImage = image
                recognizeText(in: image)
            }
        }
        .onChange(of: photosPickerItem) {
            Task {
                guard let item = photosPickerItem,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else { return }
                capturedImage = image
                recognizeText(in: image)
            }
        }
    }

    // MARK: - Recognized lines panel (shared by both paths)

    private var recognizedLinesPanel: some View {
        VStack(spacing: 14) {
            Text("Tap a line below to use it as the name or dose.")
                .font(.footnote)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(recognizedLines, id: \.self) { line in
                    lineRow(line)
                }
            }

            Button("Continue") {
                goToConfirm = true
            }
            .buttonStyle(.bigButton)
            .disabled(guessedName.isEmpty)
            .accessibilityHint(guessedName.isEmpty ? "Choose a line to use as the name first." : "Reviews this medicine before saving.")
        }
        .padding(16)
        .calmCard()
    }

    private func lineRow(_ line: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(line)
                .font(.body)
                .multilineTextAlignment(.leading)

            HStack(spacing: 10) {
                Button(nameLine == line ? "✓ Name" : "Use as name") {
                    nameLine = line
                }
                .font(.footnote.weight(.semibold))
                .frame(minHeight: 60)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(nameLine == line ? "\(line), selected as name" : "Use \(line) as name")
                .accessibilityHint("Sets this line as the medicine's name.")

                Button(doseLine == line ? "✓ Dose" : "Use as dose") {
                    doseLine = line
                }
                .font(.footnote.weight(.semibold))
                .frame(minHeight: 60)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(doseLine == line ? "\(line), selected as dose" : "Use \(line) as dose")
                .accessibilityHint("Sets this line as the medicine's dose.")
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Text recognition (fallback path)

    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                recognizedLines = lines
            }
        }
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // MARK: - Building the draft

    private var guessedName: String {
        nameLine ?? MedicineTextParsing.guessName(from: recognizedLines, excluding: doseLine)
    }

    private func finalDraft() -> MedicineDraft {
        var draft = MedicineDraft()
        draft.name = guessedName
        let doseText = doseLine ?? recognizedLines.joined(separator: " ")
        draft.dose = MedicineTextParsing.guessDose(in: doseText) ?? (doseLine ?? "")
        draft.times = MedicineTextParsing.guessTimes(in: recognizedLines.joined(separator: " "))
        if let capturedImage, let data = capturedImage.jpegData(compressionQuality: 0.8) {
            draft.photo = data
        }
        return draft
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ScanMedicineView()
    }
    .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}
#endif
