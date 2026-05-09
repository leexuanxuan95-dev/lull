import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var app: AppStore
    @State private var selection: Int = MainTabView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
            TonightView()
                .tag(0)
                .tabItem {
                    Label("Tonight", systemImage: "moon.stars.fill")
                }

            CompanionView()
                .tag(1)
                .tabItem {
                    Label("Companion", systemImage: "bubble.left.and.bubble.right.fill")
                }

            SettingsView()
                .tag(2)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .toolbarBackground(LullColors.midnight, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(LullColors.warmLamp)
    }

    /// Read `--start-tab=N` launch argument so screenshot scripts can drop the
    /// app onto a specific tab without a UI-automation dance. No effect on
    /// real users — arguments aren't passed in production.
    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let arg = args.first(where: { $0.hasPrefix("--start-tab=") }),
           let n = Int(arg.dropFirst("--start-tab=".count)),
           (0...2).contains(n) {
            return n
        }
        return 0
    }
}
