//
//  ContentView.swift
//  TapBurst
//
//  Created by Hiroaki Endo on 2026/03/03.
//

import SwiftUI

struct ContentView: View {
    let gameManager: GameManager

    var body: some View {
        switch gameManager.phase {
        case .home:
            HomeView(gameManager: gameManager)
        case .countdown:
            CountdownView(gameManager: gameManager)
        case .playing:
            GamePlayView(gameManager: gameManager)
        case .finish:
            finishPlaceholderView
        case .results:
            ResultsView(gameManager: gameManager)
        }
    }

    private var finishPlaceholderView: some View {
        Color.black
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView(gameManager: GameManager())
}
