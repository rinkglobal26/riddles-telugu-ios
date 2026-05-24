import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct TeluguRiddlesApp: App {
    @StateObject private var riddleStore = RiddleStore()
    @StateObject private var progressStore = RiddleProgressStore()

    init() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(riddleStore)
                .environmentObject(progressStore)
        }
    }
}
