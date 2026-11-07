//
//  SplashScreen.swift
//  Budgett
//
//  The native launch screen only provides the background. Branding lives here
//  so the app does not show two logos while handing off to the first screen.
//

import SwiftUI

struct SplashScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var logoOpacity = 0.0
    @State private var logoScale = 0.88
    @State private var logoOffset: CGFloat = 8
    @State private var textOpacity = 0.0
    @State private var textOffset: CGFloat = 12
    @State private var ringScale = 0.7
    @State private var ringOpacity = 0.0

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            // Adaptive background — follows system appearance
            Color(.systemBackground)
                .ignoresSafeArea()

            // Subtle radial glow behind the logo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.primary.opacity(isDark ? 0.05 : 0.04),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            VStack(spacing: 0) {
                Spacer()

                // Logo + wordmark
                VStack(spacing: 28) {
                    // App icon with decorative ring
                    ZStack {
                        Circle()
                            .strokeBorder(
                                Color.primary.opacity(isDark ? 0.08 : 0.06),
                                lineWidth: 1
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)

                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(
                                color: .black.opacity(isDark ? 0.4 : 0.12),
                                radius: 20, y: 8
                            )
                    }
                    .scaleEffect(logoScale)
                    .offset(y: logoOffset)
                    .opacity(logoOpacity)

                    // Wordmark
                    VStack(spacing: 6) {
                        Text("BUDGETT")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .tracking(4)

                        Text("Paranı daha net gör.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // Phase 1: Logo fades in and floats up
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 1
                logoScale = 1
                logoOffset = 0
            }

            // Phase 2: Ring expands
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                ringScale = 1
                ringOpacity = 1
            }

            // Phase 3: Text slides in
            withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
                textOpacity = 1
                textOffset = 0
            }
        }
    }
}
