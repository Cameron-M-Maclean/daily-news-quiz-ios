//
//  DailyNewsQuizApp.swift
//  DailyNewsQuiz
//
//  Created by Cameron Maclean on 26/03/2026.
//

import SwiftUI

@main
struct DailyNewsQuizApp: App {
    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
