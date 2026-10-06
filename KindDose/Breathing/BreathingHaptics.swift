//
//  BreathingHaptics.swift
//  KindDose
//

import CoreHaptics

/// A soft, continuously rising or falling haptic buzz timed to match a breathing
/// phase — lets the exercise work by feel alone, without needing to see the screen.
/// No-ops quietly wherever haptic hardware isn't available (e.g. the Simulator).
final class BreathingHaptics {
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    func playRising(duration: TimeInterval) {
        play(from: 0.08, to: 0.55, duration: duration)
    }

    func playFalling(duration: TimeInterval) {
        play(from: 0.55, to: 0.08, duration: duration)
    }

    private func play(from startIntensity: Float, to endIntensity: Float, duration: TimeInterval) {
        guard let engine else { return }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: startIntensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: duration
        )
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: startIntensity),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: endIntensity),
            ],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [curve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptics are a supportive extra, not essential — ignore failures.
        }
    }
}
