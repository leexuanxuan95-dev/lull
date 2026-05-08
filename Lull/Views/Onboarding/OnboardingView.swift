import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var app: AppStore

    @State private var step: Step = .lampOn
    @State private var lampIntensity: CGFloat = 0
    @State private var name: String = ""
    @State private var city: String = ""
    @State private var activity: String = ""

    enum Step: Int, CaseIterable {
        case lampOn, line1, line2, line3, name, city, activity
    }

    var body: some View {
        ZStack {
            // black → midnight as the lamp warms up
            Color.black.opacity(1 - Double(lampIntensity))
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                LampGlow(size: 240, intensity: lampIntensity)
                    .frame(height: 280)

                content
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 28)

                Spacer()

                actionButton
                    .padding(.bottom, 40)
            }
            .opacity(lampIntensity > 0.1 ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6)) {
                lampIntensity = 1.0
            }
            // Auto-advance the opening lines.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { advance() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .lampOn:
            EmptyView()
        case .line1:
            line("every story we have is for someone else.")
        case .line2:
            line("tonight's is for you.")
        case .line3:
            line("your name. your city. your kind of calm.")
        case .name:
            field(label: "your name", placeholder: "what should I call you?", text: $name)
        case .city:
            field(label: "where are you tonight?", placeholder: "your city", text: $city)
        case .activity:
            field(label: "the slow thing you used to love",
                  placeholder: "gardening · cooking · long walks · reading…",
                  text: $activity)
        }
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(LullFonts.prose(22))
            .foregroundStyle(LullColors.textPrimary)
            .multilineTextAlignment(.center)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .id(step)
    }

    private func field(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(label)
                .font(LullFonts.ui(13, weight: .medium))
                .foregroundStyle(LullColors.textSecondary)
                .textCase(.lowercase)

            LullTextField(placeholder: placeholder, text: text)
                .submitLabel(.next)
                .onSubmit { advance() }

            Text("you can change this anytime in settings.")
                .font(LullFonts.ui(12))
                .foregroundStyle(LullColors.textMuted)
        }
        .transition(.opacity)
        .id(step)
    }

    private var actionButton: some View {
        Group {
            switch step {
            case .lampOn, .line1, .line2:
                LullPrimaryButton(title: "next", action: advance)
            case .line3:
                LullPrimaryButton(title: "let's set you up", action: advance)
            case .name, .city:
                LullPrimaryButton(title: "next", action: advance)
                    .disabled(currentText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(currentText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            case .activity:
                LullPrimaryButton(title: "tonight's story", systemImage: "moon.stars", action: finish)
                    .disabled(activity.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(activity.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }
        }
    }

    private var currentText: String {
        switch step {
        case .name: return name
        case .city: return city
        case .activity: return activity
        default: return ""
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.45)) {
            switch step {
            case .lampOn:   step = .line1
            case .line1:    step = .line2
            case .line2:    step = .line3
            case .line3:    step = .name
            case .name:     step = .city
            case .city:     step = .activity
            case .activity: finish()
            }
        }
    }

    private func finish() {
        app.userName     = name.trimmingCharacters(in: .whitespaces)
        app.userCity     = city.trimmingCharacters(in: .whitespaces)
        app.userActivity = activity.trimmingCharacters(in: .whitespaces)
        withAnimation(.easeInOut(duration: 0.4)) {
            app.didOnboard = true
        }
    }
}
