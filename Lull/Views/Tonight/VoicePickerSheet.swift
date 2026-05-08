import SwiftUI

struct VoicePickerSheet: View {
    @EnvironmentObject var app: AppStore
    @EnvironmentObject var subscription: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
      NavigationStack {
        ZStack {
            MidnightBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    LullSectionHeader(
                        title: "voices",
                        subtitle: "the four base voices are free. premium voices come with Pro."
                    )

                    VStack(spacing: 10) {
                        ForEach(VoiceProfile.baseVoices) { voice in
                            voiceRow(voice, locked: false)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pro voices")
                            .font(LullFonts.ui(12, weight: .medium))
                            .foregroundStyle(LullColors.textMuted)
                            .textCase(.uppercase)

                        ForEach(VoiceProfile.proVoices) { voice in
                            voiceRow(voice, locked: !subscription.isPro)
                        }
                    }

                    if subscription.isProPlus {
                        cloneVoiceCallout
                    }
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
      }
    }

    private func voiceRow(_ voice: VoiceProfile, locked: Bool) -> some View {
        Button {
            if locked { app.paywallPresented = true; return }
            app.selectedVoiceID = voice.id
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(app.selectedVoiceID == voice.id ? LullColors.warmLamp : LullColors.hairline)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(voice.displayName)
                        .font(LullFonts.ui(15, weight: .medium))
                        .foregroundStyle(LullColors.textPrimary)
                    Text(voice.detail)
                        .font(LullFonts.prose(13))
                        .foregroundStyle(LullColors.textSecondary)
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(LullColors.textMuted)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LullColors.nightSoft.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LullColors.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var cloneVoiceCallout: some View {
        LullCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Voice clone")
                    .font(LullFonts.display(18))
                    .foregroundStyle(LullColors.textPrimary)
                Text("Pro+ — record a 30-second sample and Lull will read tonight's story in your own voice.")
                    .font(LullFonts.prose(14))
                    .foregroundStyle(LullColors.textSecondary)
                NavigationLink("set it up") {
                    VoiceCloneSetupView()
                }
                .font(LullFonts.ui(14, weight: .medium))
                .foregroundStyle(LullColors.warmLamp)
                .padding(.top, 4)
            }
        }
    }
}
