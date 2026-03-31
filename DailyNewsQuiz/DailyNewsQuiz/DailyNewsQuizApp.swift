import SwiftUI

@main
struct DailyNewsQuizApp: App {
    @StateObject private var statsManager = StatsManager()

    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(statsManager)
                .fontDesign(.rounded)
        }
    }
}
