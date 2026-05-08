import SwiftUI

@main
struct LullApp: App {
    @StateObject private var appStore = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appStore)
                .environmentObject(appStore.subscription)
                .environmentObject(appStore.voiceEngine)
                .environmentObject(appStore.vault)
                .environmentObject(appStore.sleepTimer)
                .preferredColorScheme(.dark)
                .tint(LullColors.warmLamp)
                .task {
                    await appStore.subscription.loadProducts()
                }
        }
    }
}
