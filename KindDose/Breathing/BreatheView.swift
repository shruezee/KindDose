//
//  BreatheView.swift
//  KindDose
//

import SwiftUI
import UIKit

/// A short, calm breathing exercise: 6 cycles of breathe-in (4s) / breathe-out (6s),
/// about a minute total. No breath holding. Works by sight, sound (haptics), or
/// VoiceOver announcement alone.
struct BreatheView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase {
        case breatheIn, breatheOut

        var label: String {
            switch self {
            case .breatheIn: "Breathe in"
            case .breatheOut: "Breathe out"
            }
        }
    }

    private let totalCycles = 6
    private let breatheInDuration = 4.0
    private let breatheOutDuration = 6.0

    @State private var phase: Phase = .breatheIn
    @State private var isFinished = false
    @State private var circleScale: CGFloat = 0.6
    @State private var fadeAmount: Double = 0
    @State private var runLoop: Task<Void, Never>?
    @State private var haptics = BreathingHaptics()

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 0)

                    if isFinished {
                        Text("Well done. You're calm and ready for the next one. 🌿")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .calmCard()
                            .accessibilityAddTraits(.isHeader)
                    } else {
                        breathingIndicator
                            .frame(height: 220)

                        Text(phase.label)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .calmCard()
                    }

                    Spacer(minLength: 0)

                    Button("Stop", action: stop)
                        .buttonStyle(.bigButton)
                        .accessibilityHint("Stops the breathing exercise now.")
                }
                .padding(24)
                .calmScreenWidth()
                .containerRelativeFrame(.vertical)
            }
        }
        .onAppear { start() }
        .onDisappear { runLoop?.cancel() }
    }

    @ViewBuilder
    private var breathingIndicator: some View {
        if reduceMotion {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CalmColor.actionBackground.opacity(0.25 + fadeAmount * 0.55))
                .accessibilityHidden(true)
        } else {
            Circle()
                .fill(CalmColor.actionBackground)
                .frame(width: 200 * circleScale, height: 200 * circleScale)
                .accessibilityHidden(true)
        }
    }

    private func start() {
        runLoop = Task {
            for _ in 0..<totalCycles {
                guard !Task.isCancelled else { return }
                await runPhase(.breatheIn, duration: breatheInDuration)
                guard !Task.isCancelled else { return }
                await runPhase(.breatheOut, duration: breatheOutDuration)
            }
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func runPhase(_ newPhase: Phase, duration: Double) async {
        phase = newPhase
        UIAccessibility.post(notification: .announcement, argument: newPhase.label)

        switch newPhase {
        case .breatheIn: haptics.playRising(duration: duration)
        case .breatheOut: haptics.playFalling(duration: duration)
        }

        withAnimation(.easeInOut(duration: duration)) {
            if reduceMotion {
                fadeAmount = newPhase == .breatheIn ? 1 : 0
            } else {
                circleScale = newPhase == .breatheIn ? 1.0 : 0.6
            }
        }

        try? await Task.sleep(for: .seconds(duration))
    }

    private func finish() {
        isFinished = true
        UIAccessibility.post(notification: .announcement, argument: "Well done. You're calm and ready for the next one.")
    }

    private func stop() {
        runLoop?.cancel()
        onFinished()
    }
}

#if DEBUG
#Preview {
    BreatheView(onFinished: {})
}
#endif
