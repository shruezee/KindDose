//
//  ProgressDotsView.swift
//  KindDose
//

import SwiftUI

/// Decorative progress indicator. VoiceOver hears a single "Step X of Y" label
/// instead of each dot, per project.md's logical reading order rule.
struct ProgressDotsView: View {
    var current: Int
    var total: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? CalmColor.actionBackground : CalmColor.actionBackground.opacity(0.25))
                    .frame(width: index == current ? 12 : 8, height: index == current ? 12 : 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

#if DEBUG
#Preview {
    ProgressDotsView(current: 2, total: OnboardingStep.allCases.count)
}
#endif
