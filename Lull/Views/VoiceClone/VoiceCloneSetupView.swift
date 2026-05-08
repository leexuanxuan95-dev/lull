import SwiftUI

/// Pro+ feature: simulated voice-clone onboarding. We don't actually train a
/// voice in-app — that's a server-side/PersonalVoice concern — but we reflect
/// the spec's flow so the screen exists, with permissions and copy in place.
struct VoiceCloneSetupView: View {
    @EnvironmentObject var app: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var stage: Stage = .intro
    @State private var fakeProgress: Double = 0
    @State private var timer: Timer?

    enum Stage { case intro, recording, training, done }

    private let sampleText = """
    "tonight's story is for you. your name. your city. \
    the slow thing you used to love. take your time reading this — \
    it's only thirty seconds."
    """

    var body: some View {
        ZStack {
            MidnightBackground()

            VStack(spacing: 24) {
                header
                Spacer()
                content
                Spacer()
                actionRow
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(stage == .training)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("voice clone")
                .font(LullFonts.display(30))
                .foregroundStyle(LullColors.textPrimary)
            Text("Pro+ · 30-second sample → your own narrator voice")
                .font(LullFonts.ui(13))
                .foregroundStyle(LullColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch stage {
        case .intro:
            VStack(alignment: .leading, spacing: 18) {
                Text("read this aloud, slowly, when you tap record:")
                    .font(LullFonts.ui(14, weight: .medium))
                    .foregroundStyle(LullColors.textSecondary)

                Text(sampleText)
                    .font(LullFonts.prose(18))
                    .foregroundStyle(LullColors.textPrimary)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LullColors.nightSoft.opacity(0.6))
                    )

                privacyRow
            }

        case .recording:
            VStack(spacing: 16) {
                LampGlow(size: 120, intensity: 1.0)
                    .frame(height: 160)
                Text("recording…")
                    .font(LullFonts.ui(14))
                    .foregroundStyle(LullColors.textSecondary)
                Text(sampleText)
                    .font(LullFonts.prose(15))
                    .foregroundStyle(LullColors.textPrimary)
                    .multilineTextAlignment(.center)
            }

        case .training:
            VStack(spacing: 20) {
                LampGlow(size: 110, intensity: 0.8)
                    .frame(height: 140)
                ProgressView(value: fakeProgress)
                    .tint(LullColors.warmLamp)
                Text("training your voice profile…")
                    .font(LullFonts.ui(14))
                    .foregroundStyle(LullColors.textSecondary)
                Text("this stays on your iCloud. no audio leaves your phone.")
                    .font(LullFonts.ui(12))
                    .foregroundStyle(LullColors.textMuted)
                    .multilineTextAlignment(.center)
            }

        case .done:
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LullColors.warmLamp)
                Text("voice ready")
                    .font(LullFonts.display(24))
                    .foregroundStyle(LullColors.textPrimary)
                Text("you can pick \"your voice\" in voice settings tonight.")
                    .font(LullFonts.prose(15))
                    .foregroundStyle(LullColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var privacyRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundStyle(LullColors.textSecondary)
            Text("your voice never leaves your iCloud.")
                .font(LullFonts.ui(13))
                .foregroundStyle(LullColors.textSecondary)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        switch stage {
        case .intro:
            HStack(spacing: 10) {
                LullGhostButton(title: "not yet") { dismiss() }
                Spacer()
                LullPrimaryButton(title: "record", systemImage: "mic.fill") {
                    stage = .recording
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        stage = .training
                        fakeProgress = 0
                        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
                            DispatchQueue.main.async {
                                fakeProgress += 0.02
                                if fakeProgress >= 1.0 {
                                    t.invalidate()
                                    stage = .done
                                    app.hasCloneVoice = true
                                }
                            }
                        }
                    }
                }
            }
        case .recording:
            LullGhostButton(title: "cancel") {
                stage = .intro
            }
            .frame(maxWidth: .infinity)
        case .training:
            EmptyView()
        case .done:
            LullPrimaryButton(title: "done") { dismiss() }
                .frame(maxWidth: .infinity)
        }
    }
}
