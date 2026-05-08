import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppStore

    var body: some View {
        ZStack {
            MidnightBackground()

            if !app.didOnboard {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .fullScreenCover(item: $app.listeningStory) { story in
            ListeningView(story: story)
                .environmentObject(app)
        }
        .sheet(isPresented: $app.paywallPresented) {
            PaywallView()
                .environmentObject(app)
        }
        .animation(.easeInOut(duration: 0.4), value: app.didOnboard)
    }
}
