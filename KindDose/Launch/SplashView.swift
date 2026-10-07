//
//  SplashView.swift
//  KindDose
//

import SwiftUI
import UIKit

/// Shown briefly on launch while KindDose sets itself up. Calm background, the app's
/// mark on a solid card (never directly on the gradient), a short status message, and
/// a copyright footer. Falls back to a simple branded mark until real icon artwork is
/// added to the "AppIconMark" image set in Assets.xcassets — swap that image and this
/// view will automatically pick it up.
struct SplashView: View {
    var body: some View {
        ZStack {
            CalmBackground()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    appMark
                        .frame(width: 120, height: 120)

                    Text("Setting up…")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .padding(28)
                .calmCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("KindDose")
                .accessibilityValue("Setting up")

                Spacer()

                Text("© 2026 Shruezee Studio")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding(24)
            .calmScreenWidth()
        }
    }

    @ViewBuilder
    private var appMark: some View {
        if let uiImage = UIImage(named: "AppIconMark") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(CalmColor.actionBackground)
                .overlay(
                    Image(systemName: "pills.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                )
                .accessibilityHidden(true)
        }
    }
}

#if DEBUG
#Preview {
    SplashView()
}
#endif
