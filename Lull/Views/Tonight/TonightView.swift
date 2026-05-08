import SwiftUI

struct TonightView: View {
    @EnvironmentObject var app: AppStore
    @State private var voicePickerOpen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Title + lamp
                VStack(alignment: .leading, spacing: 6) {
                    Text("tonight")
                        .font(LullFonts.display(40))
                        .foregroundStyle(LullColors.textPrimary)
                    Text("a story for \(app.profile.displayName.lowercased())")
                        .font(LullFonts.prose(18))
                        .foregroundStyle(LullColors.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Genre cards
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14)],
                          spacing: 14) {
                    ForEach(Genre.allCases) { genre in
                        GenreCard(genre: genre,
                                  profile: app.profile,
                                  onPlay: { play(genre) })
                    }
                }
                .padding(.horizontal, 18)

                // Voice picker
                voicePicker

                Spacer(minLength: 40)
            }
            .padding(.bottom, 30)
        }
        .background(MidnightBackground())
        .sheet(isPresented: $voicePickerOpen) {
            VoicePickerSheet()
                .environmentObject(app)
                .presentationDetents([.medium, .large])
        }
    }

    private var voicePicker: some View {
        Button { voicePickerOpen = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "waveform")
                    .foregroundStyle(LullColors.warmLamp)
                VStack(alignment: .leading, spacing: 2) {
                    Text("voice")
                        .font(LullFonts.ui(12, weight: .medium))
                        .foregroundStyle(LullColors.textMuted)
                        .textCase(.uppercase)
                    Text(app.selectedVoice.displayName)
                        .font(LullFonts.ui(15, weight: .medium))
                        .foregroundStyle(LullColors.textPrimary)
                }
                Spacer()
                Text(app.selectedVoice.detail)
                    .font(LullFonts.prose(13))
                    .foregroundStyle(LullColors.textSecondary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(LullColors.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LullColors.nightSoft.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(LullColors.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
    }

    private func play(_ genre: Genre) {
        let story = app.ensureTonightStory(for: genre)
        app.startListening(story)
    }
}
