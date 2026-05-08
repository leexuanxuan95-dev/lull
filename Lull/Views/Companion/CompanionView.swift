import SwiftUI

struct CompanionView: View {
    @EnvironmentObject var app: AppStore
    @EnvironmentObject var vault: LullVault
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool
    @State private var greetingShown: Bool = false

    var body: some View {
        ZStack {
            MidnightBackground()

            VStack(spacing: 0) {
                header
                Divider().background(LullColors.hairline)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            if vault.chat.isEmpty {
                                emptyState
                                    .padding(.top, 40)
                            } else {
                                ForEach(vault.chat) { msg in
                                    MessageBubble(message: msg)
                                        .id(msg.id)
                                }
                            }
                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                    }
                    .onChange(of: vault.chat.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }

                composer
            }
        }
        .onAppear { ensureGreeting() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("companion")
                .font(LullFonts.display(28))
                .foregroundStyle(LullColors.textPrimary)
            Text("a quiet voice for nights you can't sleep")
                .font(LullFonts.prose(14))
                .foregroundStyle(LullColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            LampGlow(size: 140, intensity: 0.7)
                .frame(height: 160)
            Text("type how the night feels.\nI'll keep my voice low.")
                .font(LullFonts.prose(16))
                .foregroundStyle(LullColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 30)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            LullTextField(placeholder: "what's the night doing?",
                          text: $draft,
                          axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { send() }

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LullColors.midnight)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(canSend ? LullColors.warmLamp : LullColors.warmLamp.opacity(0.4)))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(LullColors.nightDeep.opacity(0.85))
        .overlay(
            Rectangle()
                .fill(LullColors.hairline)
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)
        )
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func ensureGreeting() {
        guard !greetingShown, vault.chat.isEmpty else {
            greetingShown = true
            return
        }
        greetingShown = true
        let seed = SeedHasher.hash("greet", app.profile.displayName,
                                   ISO8601DateFormatter.dayKey(for: Date()))
        let body = CompanionChat.initialGreeting(profile: app.profile, seed: seed)
        let msg = ChatMessage(role: .companion, body: body)
        // small delay so it doesn't appear before the view animates in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vault.appendChat(msg)
        }
    }

    private func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft = ""

        let userMsg = ChatMessage(role: .user, body: trimmed)
        vault.appendChat(userMsg)

        // Companion replies after a short, intentional pause — feels less
        // like a chatbot, more like a person finding their words.
        let history = vault.chat
        let extra = "\(Date().timeIntervalSince1970)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let reply = CompanionChat.reply(
                to: trimmed,
                history: history,
                profile: app.profile,
                extraEntropy: extra
            )
            vault.appendChat(ChatMessage(role: .companion, body: reply))
        }
    }
}

// MARK: - bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user { Spacer(minLength: 40) }

            Text(message.body)
                .font(message.role == .user
                      ? LullFonts.ui(15)
                      : LullFonts.prose(16))
                .foregroundStyle(message.role == .user
                                 ? LullColors.midnight
                                 : LullColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(bubbleBackground)
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .companion { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LullColors.warmLamp)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LullColors.nightSoft.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LullColors.hairline, lineWidth: 1)
                )
        }
    }
}
