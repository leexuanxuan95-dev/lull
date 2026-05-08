import SwiftUI

// MARK: - Backgrounds

struct MidnightBackground: View {
    var body: some View {
        LinearGradient(
            colors: [LullColors.nightDeep, LullColors.midnight, LullColors.nightSoft.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Lamp glow

/// Soft warm circle radiating moon-cream light. Used as the app's core motif
/// — onboarding, paywall, "tonight's story" empty state.
struct LampGlow: View {
    var size: CGFloat = 220
    var intensity: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LullColors.warmLamp.opacity(0.55 * intensity),
                            LullColors.warmLamp.opacity(0.15 * intensity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: 30)

            Circle()
                .fill(LullColors.warmLamp.opacity(0.85 * intensity))
                .frame(width: size * 0.18, height: size * 0.18)
                .blur(radius: 4)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Buttons

struct LullPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
                    .font(LullFonts.ui(16, weight: .medium))
            }
            .foregroundStyle(LullColors.midnight)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(LullColors.warmLamp)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LullGhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LullFonts.ui(15, weight: .medium))
                .foregroundStyle(LullColors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(
                    Capsule().stroke(LullColors.textPrimary.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card

struct LullCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LullColors.nightSoft.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LullColors.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Text field

struct LullTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .font(LullFonts.ui(16))
            .foregroundStyle(LullColors.textPrimary)
            .tint(LullColors.warmLamp)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LullColors.nightSoft.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LullColors.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Section header

struct LullSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LullFonts.display(26, weight: .regular))
                .foregroundStyle(LullColors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(LullFonts.ui(14))
                    .foregroundStyle(LullColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
