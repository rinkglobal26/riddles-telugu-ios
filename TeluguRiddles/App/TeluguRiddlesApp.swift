import SwiftUI

@main
struct TeluguRiddlesApp: App {
    @StateObject private var riddleStore = RiddleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(riddleStore)
        }
    }
}
