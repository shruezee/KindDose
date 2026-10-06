//
//  SpeakMedicineView.swift
//  KindDose
//

import SwiftUI
import SwiftData
import Speech
import AVFoundation

/// Speaks the medicine name and dose out loud, e.g. "Metformin 500 milligrams
/// morning and night," using on-device speech recognition where the device
/// supports it. Always ends on the "Is this correct?" confirm screen.
struct SpeakMedicineView: View {
    @State private var transcript = ""
    @State private var isRecording = false
    @State private var permissionDenied = false
    @State private var goToConfirm = false

    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Speak the medicine")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .calmCard()

                    Text("Say something like \"Metformin 500 milligrams morning and night.\"")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .calmCard()

                    if permissionDenied {
                        Text("KindDose needs microphone and speech permission to do this. You can allow it in Settings → KindDose.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .calmCard()
                    } else {
                        Button {
                            isRecording ? stopRecording() : startRecording()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 48))
                                Text(isRecording ? "Listening… tap to stop" : "Tap to speak")
                                    .font(.body.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 140)
                        }
                        .buttonStyle(.bigButton)
                        .accessibilityLabel(isRecording ? "Stop listening" : "Start speaking")
                        .accessibilityHint("Starts or stops listening for the medicine name and dose.")

                        if !transcript.isEmpty {
                            Text(transcript)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .calmCard()
                        }

                        Button("Continue") {
                            goToConfirm = true
                        }
                        .buttonStyle(.bigButton)
                        .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityHint(transcript.isEmpty ? "Speak the medicine first." : "Reviews this medicine before saving.")
                    }
                }
                .padding(24)
                .calmScreenWidth()
            }
        }
        .navigationTitle("Speak")
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $goToConfirm) {
            AddMedicineConfirmView(draft: makeDraft())
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            AVAudioApplication.requestRecordPermission { micGranted in
                DispatchQueue.main.async {
                    guard speechStatus == .authorized, micGranted else {
                        permissionDenied = true
                        return
                    }
                    beginRecognition()
                }
            }
        }
    }

    private func beginRecognition() {
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return
        }
        isRecording = true

        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let result {
                DispatchQueue.main.async {
                    transcript = result.bestTranscription.formattedString
                }
            }
            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async { stopRecording() }
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    private func makeDraft() -> MedicineDraft {
        var draft = MedicineDraft()
        let dose = MedicineTextParsing.guessDose(in: transcript)
        draft.dose = dose ?? ""
        draft.times = MedicineTextParsing.guessTimes(in: transcript)
        draft.name = MedicineTextParsing.guessName(from: [transcript], excluding: dose)
        return draft
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SpeakMedicineView()
    }
    .modelContainer(for: [Medicine.self, DoseLog.self, UserSettings.self], inMemory: true)
}
#endif
