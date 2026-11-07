//
//  Glass.swift
//  Budgett
//
//  Surface language. One quiet card style everywhere; the only translucent
//  material left is the floating tab bar.
//

import SwiftUI

// MARK: - Cards

struct AppSurface: ViewModifier {
    var radius: CGFloat = Metrics.cardRadius

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
    }
}

extension View {
    /// The app's single card treatment. `tint` and `interactive` are accepted so
    /// older call sites keep compiling, but the surface is deliberately uniform.
    func glassCard(radius: CGFloat = Metrics.cardRadius, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(AppSurface(radius: radius))
    }

    func softCard(radius: CGFloat = Metrics.cardRadius) -> some View {
        modifier(AppSurface(radius: radius))
    }

    @ViewBuilder
    func hidden(_ isHidden: Bool) -> some View {
        if isHidden { self.hidden() } else { self }
    }
}

// MARK: - Background

/// Flat page background. Keeps the `accent:` parameter so screens don't need to
/// change when the palette does.
struct AuroraBackground: View {
    var accent: ThemeAccent = .mono

    var body: some View {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }
}

// MARK: - Press feedback

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

// MARK: - Prominent button

/// Ink-on-paper pill. The system `.glassProminent` style picks up the app's
/// monochrome tint, which turns into a white pill with a white label in dark
/// mode. This style always inverts against the current ink so the label stays
/// readable in both appearances.
struct InkProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15.5, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                Capsule().fill(Color.primary.opacity(isEnabled ? 1 : 0.35))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InkProminentButtonStyle {
    static var inkProminent: InkProminentButtonStyle { InkProminentButtonStyle() }
}

// MARK: - Tab bar clearance

extension View {
    /// Reserves room at the end of a scrollable screen so the floating tab bar
    /// never covers the last row. Pushed settings screens need this too.
    func tabBarContentInset() -> some View {
        contentMargins(.bottom, Metrics.tabBarClearance, for: .scrollContent)
    }
}

