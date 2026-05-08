import SwiftUI
import Combine

struct ListeningView: View {
    let story: GeneratedStory

    @EnvironmentObject var app: AppStore
    @EnvironmentObject var voiceEngine: VoiceEngine
    @EnvironmentObject var sleepTimer: SleepDetector
    @Environment(\.dismiss) private var dismiss

    @State private var fadeOut: Bool = false
    @State private var showProse: Bool = false
    @State private var dimming: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            // night sky
            LinearGradient(
                colors: [Color.black, LullColors.nightDeep, LullColors.midnight],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            StarFieldView(seed: story.seed)
                .opacity(0.7)

            VStack(spacing: 28) {
                topBar

                Spacer()

                VStack(spacing: 14) {
                    Text(story.title)
                        .font(LullFonts.display(28))
                        .foregroundStyle(LullColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(story.genre.tagline)
                        .font(LullFonts.prose(14))
                        .foregroundStyle(LullColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                if showProse {
                    proseScroller
                        .transition(.opacity)
                }

                controls
                    .padding(.bottom, 40)
            }
        }
        .opacity(fadeOut ? 0.05 : (dimming ? 0.6 : 1))
        .animation(.easeInOut(duration: 4), value: fadeOut)
        .animation(.easeInOut(duration: 8), value: dimming)
        .onAppear {
            wireUp()
            // start the gradual screen-dim that the spec calls for
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                dimming = true
            }
        }
        .onDisappear {
            // listening view dismissed — make sure audio + timer stop with it
            app.stopListening()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - sub-views

    private var topBar: some View {
        HStack {
            Button {
                app.stopListening()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(LullColors.textSecondary)
                    .padding(12)
                    .background(Circle().fill(LullColors.nightSoft.opacity(0.4)))
            }

            Spacer()

            Text("\(story.estimatedDurationMinutes) min · \(app.selectedVoice.displayName)")
                .font(LullFonts.ui(12))
                .foregroundStyle(LullColors.textMuted)
                .textCase(.uppercase)

            Spacer()

            Button {
                withAnimation { showProse.toggle() }
            } label: {
                Image(systemName: showProse ? "text.alignleft" : "eye.slash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(showProse ? LullColors.warmLamp : LullColors.textSecondary)
                    .padding(12)
                    .background(Circle().fill(LullColors.nightSoft.opacity(0.4)))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var proseScroller: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(story.paragraphs.enumerated()), id: \.offset) { idx, p in
                    Text(p)
                        .font(LullFonts.prose(15))
                        .foregroundStyle(idx < voiceEngine.paragraphIndex
                                         ? LullColors.textMuted
                                         : LullColors.textPrimary)
                        .padding(.horizontal, 28)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 180)
        .mask(
            LinearGradient(colors: [.clear, .black, .black, .clear],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Text(timerLabel)
                .font(LullFonts.ui(11))
                .foregroundStyle(LullColors.textMuted)
                .textCase(.uppercase)

            HStack(spacing: 36) {
                Button { voiceEngine.stop(); app.stopListening(); dismiss() } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(LullColors.textSecondary)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(LullColors.nightSoft.opacity(0.5)))
                }

                Button {
                    if voiceEngine.isPlaying { voiceEngine.pause() }
                    else { voiceEngine.resume() }
                } label: {
                    Image(systemName: voiceEngine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(LullColors.midnight)
                        .frame(width: 84, height: 84)
                        .background(Circle().fill(LullColors.warmLamp))
                }

                Menu {
                    ForEach(SleepDetector.Mode.allCases) { mode in
                        Button {
                            app.sleepTimerMode = mode
                            sleepTimer.mode = mode
                            sleepTimer.start()
                        } label: {
                            if mode == app.sleepTimerMode {
                                Label(mode.displayName, systemImage: "checkmark")
                            } else {
                                Text(mode.displayName)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(LullColors.textSecondary)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(LullColors.nightSoft.opacity(0.5)))
                }
            }
        }
    }

    private var timerLabel: String {
        let mode = sleepTimer.mode
        switch mode {
        case .untilAsleep: return "until you're asleep"
        default:
            let remaining = max(0, mode.capSeconds - sleepTimer.elapsed)
            let mins = Int(remaining / 60)
            return "\(mins) min remaining · \(mode.displayName)"
        }
    }

    // MARK: - bindings

    private func wireUp() {
        cancellables.removeAll()

        // sleep timer reaches its cap → fade audio out and dismiss
        sleepTimer.$shouldFadeOut
            .sink { fade in
                if fade { triggerFadeOut() }
            }
            .store(in: &cancellables)

        // story finishes naturally → fade & dismiss
        voiceEngine.didFinish
            .sink { _ in triggerFadeOut() }
            .store(in: &cancellables)
    }

    private func triggerFadeOut() {
        fadeOut = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            app.stopListening()
            dismiss()
        }
    }
}
