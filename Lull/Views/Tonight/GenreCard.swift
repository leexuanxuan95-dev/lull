import SwiftUI

struct GenreCard: View {
    let genre: Genre
    let profile: UserStoryProfile
    let onPlay: () -> Void

    @State private var preview: String = ""
    @State private var pressed = false

    var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(genre.emoji)
                        .font(.system(size: 24))
                    Spacer()
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(LullColors.warmLamp)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(genre.displayName)
                        .font(LullFonts.display(19))
                        .foregroundStyle(LullColors.textPrimary)
                    Text(genre.tagline)
                        .font(LullFonts.ui(11))
                        .foregroundStyle(LullColors.textMuted)
                        .textCase(.lowercase)
                }

                Text(preview)
                    .font(LullFonts.prose(13))
                    .foregroundStyle(LullColors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LullColors.nightSoft.opacity(pressed ? 0.85 : 0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LullColors.hairline, lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .onAppear { regeneratePreview() }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.001)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private func regeneratePreview() {
        // Stable preview per (day, genre, name) so a returning user sees
        // the same teaser as last time they opened the app today.
        let day = ISO8601DateFormatter.dayKey(for: Date())
        let seed = SeedHasher.hash("preview", day, profile.displayName, genre.rawValue)
        preview = StoryGenerator.previewLine(for: genre, profile: profile, seed: seed)
    }
}
