//
//  TapBurstApp.swift
//  TapBurst
//
//  Created by Hiroaki Endo on 2026/03/03.
//

import SwiftUI

@main
struct TapBurstApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var gameManager = GameManager()

    var body: some Scene {
        WindowGroup {
            ContentView(gameManager: gameManager)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        gameManager.handleBackground()
                    }
                }
        }
    }
}
