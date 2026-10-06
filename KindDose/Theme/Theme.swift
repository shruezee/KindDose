//
//  Theme.swift
//  KindDose
//

import SwiftUI

// MARK: - Time of day

enum TimeOfDay {
    case morning, afternoon, evening, night

    static func current(for date: Date = Date()) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    /// Calm gradients for each time of day. Used only when motion/transparency/contrast settings allow it.
    var gradientColors: [Color] {
        switch self {
        case .morning: [Color(red: 0.78, green: 0.88, blue: 0.97), Color(red: 0.56, green: 0.75, blue: 0.92)]
        case .afternoon: [Color(red: 0.82, green: 0.91, blue: 0.80), Color(red: 0.58, green: 0.76, blue: 0.62)]
        case .evening: [Color(red: 0.98, green: 0.89, blue: 0.76), Color(red: 0.93, green: 0.72, blue: 0.58)]
        case .night: [Color(red: 0.16, green: 0.21, blue: 0.35), Color(red: 0.07, green: 0.10, blue: 0.20)]
        }
    }

    /// A single flat colour standing in for the gradient when reduced motion/transparency or increased contrast is on.
    var solidColor: Color {
        gradientColors.last ?? Color(.systemBackground)
    }

    /// Plain word for "which medicine time this is," used in validation messages.
    var medicinePeriodLabel: String {
        switch self {
        case .morning: "morning"
        case .afternoon: "afternoon"
        case .evening: "evening"
        case .night: "night"
        }
    }
}

// MARK: - Text size preference → Dynamic Type floor

extension TextSizePreference {
    /// A floor applied app-wide on top of the system's own Dynamic Type setting —
    /// never smaller than this, but still grows further if the system setting is larger.
    var minimumDynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard: .xSmall
        case .big: .xLarge
        case .bigger: .accessibility1
        case .biggest: .accessibility3
        }
    }
}

// MARK: - Calm background

/// A calm, time-of-day gradient backdrop. Falls back to a plain solid colour for
/// Reduce Motion, Increase Contrast, or Reduce Transparency, per project.md.
struct CalmBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var timeOfDay: TimeOfDay = .current()

    private var usesSolidColor: Bool {
        reduceMotion || reduceTransparency || colorSchemeContrast == .increased
    }

    var body: some View {
        Group {
            if usesSolidColor {
                timeOfDay.solidColor
            } else {
                LinearGradient(colors: timeOfDay.gradientColors, startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Calm colours (WCAG AA in light and dark)

enum CalmColor {
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.16) : .white
    }

    /// ~18:1 contrast against cardBackground in light mode, ~13:1 in dark mode.
    static func cardText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.96) : Color(white: 0.08)
    }

    /// ~5.7:1 contrast against white, safe for both normal and large text.
    static let actionBackground = Color(red: 0.16, green: 0.42, blue: 0.62)
    static let actionText = Color.white
}

// MARK: - Card

private struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(CalmColor.cardText(for: colorScheme))
            .padding()
            .background(CalmColor.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    /// Places content on a solid, high-contrast card. Text must never sit directly on a gradient.
    func calmCard() -> some View {
        modifier(CardModifier())
    }

    /// Caps a screen's main content at a comfortable reading width and centers it,
    /// so text and controls don't stretch edge-to-edge on wide iPad screens.
    func calmScreenWidth() -> some View {
        self
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Big button

struct BigButtonStyle: ButtonStyle {
    var backgroundColor: Color = CalmColor.actionBackground
    var foregroundColor: Color = CalmColor.actionText

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.bold())
            .frame(minHeight: 72)
            .frame(maxWidth: .infinity)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 20)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .sensoryFeedback(.impact(weight: .medium), trigger: configuration.isPressed) { oldValue, newValue in
                newValue && !oldValue
            }
    }
}

extension ButtonStyle where Self == BigButtonStyle {
    static var bigButton: BigButtonStyle { BigButtonStyle() }
}
