import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var app: AppStore

    var body: some View {
        TabView {
            TonightView()
                .tabItem {
                    Label("Tonight", systemImage: "moon.stars.fill")
                }

            CompanionView()
                .tabItem {
                    Label("Companion", systemImage: "bubble.left.and.bubble.right.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .toolbarBackground(LullColors.midnight, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(LullColors.warmLamp)
    }
}
