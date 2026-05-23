import SwiftUI

@main
struct TeluguRiddlesApp: App {
    @StateObject private var riddleStore = RiddleStore()
    @StateObject private var progressStore = RiddleProgressStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(riddleStore)
                .environmentObject(progressStore)
        }
    }
}
