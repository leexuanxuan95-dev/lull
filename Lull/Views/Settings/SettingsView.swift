import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppStore
    @EnvironmentObject var vault: LullVault
    @EnvironmentObject var subscription: SubscriptionStore

    var body: some View {
        NavigationStack {
            ZStack {
                MidnightBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings")
                                .font(LullFonts.display(30))
                                .foregroundStyle(LullColors.textPrimary)
                            Text("the small things that make the night yours.")
                                .font(LullFonts.prose(14))
                                .foregroundStyle(LullColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // profile
                        LullCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("about you")
                                    .font(LullFonts.ui(12, weight: .medium))
                                    .foregroundStyle(LullColors.textMuted)
                                    .textCase(.uppercase)

                                fieldRow(label: "name", text: $app.userName, placeholder: "your name")
                                fieldRow(label: "city", text: $app.userCity, placeholder: "your city")
                                fieldRow(label: "the slow thing you love",
                                         text: $app.userActivity,
                                         placeholder: "gardening, walking, cooking…")
                            }
                        }

                        // sleep
                        LullCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("sleep timer default")
                                    .font(LullFonts.ui(12, weight: .medium))
                                    .foregroundStyle(LullColors.textMuted)
                                    .textCase(.uppercase)

                                ForEach(SleepDetector.Mode.allCases) { mode in
                                    Button { app.sleepTimerMode = mode } label: {
                                        HStack {
                                            Text(mode.displayName)
                                                .font(LullFonts.ui(15))
                                                .foregroundStyle(LullColors.textPrimary)
                                            Spacer()
                                            if app.sleepTimerMode == mode {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(LullColors.warmLamp)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // smart wake / voice clone navigation
                        VStack(spacing: 10) {
                            NavigationLink {
                                SmartWakeView()
                            } label: {
                                navRow(icon: "alarm.waves.left.and.right",
                                       title: "smart wake",
                                       subtitle: "nature sounds before alarm · Pro")
                            }

                            NavigationLink {
                                VoiceCloneSetupView()
                            } label: {
                                navRow(icon: "waveform.badge.mic",
                                       title: app.hasCloneVoice ? "voice clone — re-record" : "voice clone setup",
                                       subtitle: "Pro+ · 30-second sample → your own narrator")
                            }
                        }

                        // subscription state + paywall
                        LullCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("subscription")
                                    .font(LullFonts.ui(12, weight: .medium))
                                    .foregroundStyle(LullColors.textMuted)
                                    .textCase(.uppercase)

                                Text(tierLabel)
                                    .font(LullFonts.ui(15, weight: .medium))
                                    .foregroundStyle(LullColors.textPrimary)

                                if !subscription.isPro {
                                    LullPrimaryButton(title: "go Pro") {
                                        app.paywallPresented = true
                                    }
                                } else {
                                    LullGhostButton(title: "manage") {
                                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                }
                            }
                        }

                        // chat utility
                        LullCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("companion")
                                    .font(LullFonts.ui(12, weight: .medium))
                                    .foregroundStyle(LullColors.textMuted)
                                    .textCase(.uppercase)
                                Button(role: .destructive) {
                                    vault.clearChat()
                                } label: {
                                    Text("clear conversation")
                                        .font(LullFonts.ui(15, weight: .medium))
                                }
                            }
                        }

                        // legal — App Store reviewers need these visible
                        LullCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("legal")
                                    .font(LullFonts.ui(12, weight: .medium))
                                    .foregroundStyle(LullColors.textMuted)
                                    .textCase(.uppercase)

                                legalLink("Privacy Policy",
                                          url: "https://leexuanxuan95-dev.github.io/lull/privacy.html")
                                legalLink("Terms of Use",
                                          url: "https://leexuanxuan95-dev.github.io/lull/terms.html")
                                legalLink("Subscription EULA",
                                          url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
                                legalLink("Support",
                                          url: "https://leexuanxuan95-dev.github.io/lull/support.html")
                            }
                        }

                        // tiny credit
                        VStack(spacing: 4) {
                            Text("Lull · 1.0")
                                .font(LullFonts.ui(12))
                                .foregroundStyle(LullColors.textMuted)
                            Text("every story is generated for you, on this phone.")
                                .font(LullFonts.prose(12))
                                .foregroundStyle(LullColors.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(LullColors.midnight, for: .navigationBar)
        }
    }

    private var tierLabel: String {
        switch subscription.tier {
        case .free:     return "Free · 1 story per night"
        case .pro:      return "Pro · unlimited stories + premium voices"
        case .proPlus:  return "Pro+ · everything, plus voice clone"
        case .lifetime: return "Lifetime · all features, forever (incl. voice clone)"
        }
    }

    private func fieldRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(LullFonts.ui(12))
                .foregroundStyle(LullColors.textMuted)
                .textCase(.lowercase)
            LullTextField(placeholder: placeholder, text: text)
        }
    }

    private func legalLink(_ title: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) { UIApplication.shared.open(u) }
        } label: {
            HStack {
                Text(title)
                    .font(LullFonts.ui(15))
                    .foregroundStyle(LullColors.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13))
                    .foregroundStyle(LullColors.textMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private func navRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(LullColors.warmLamp)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LullFonts.ui(15, weight: .medium))
                    .foregroundStyle(LullColors.textPrimary)
                Text(subtitle)
                    .font(LullFonts.prose(12))
                    .foregroundStyle(LullColors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(LullColors.textMuted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LullColors.nightSoft.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LullColors.hairline, lineWidth: 1)
        )
    }
}
