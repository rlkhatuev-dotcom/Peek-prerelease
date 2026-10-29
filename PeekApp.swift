import SwiftUI

@main
struct PeekApp: App {
    @StateObject private var store = PeekStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.darkMode ? .dark : .light)
        }
    }
}
