import SwiftUI

@main
struct KradoWatchApp: App {
    @StateObject private var healthManager = HealthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { healthManager.requestAuthorization() }
        }
    }
}
