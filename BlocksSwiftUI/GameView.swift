//
//  GameView.swift
//  BlocksSwiftUI
//
//  Created by Ruben Grill on 09.04.23.
//

import SwiftUI

struct GameView: View {

    @ObservedObject
    var gameModel: GameModel

    @State
    private var showGameOver = false

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        BoardView(gameModel: gameModel)
            .background(Color("background"))
            .onAppear {
                gameModel.start()
            }
            .onChange(of: gameModel.isOver) {
                showGameOver = gameModel.isOver
            }
            .alert(
                "Game over!",
                isPresented: $showGameOver,
                actions: {
                    Button("No") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Yes") {
                        gameModel.reset()
                        gameModel.start()
                    }
                    .keyboardShortcut(.defaultAction)
                },
                message: {
                    Text("Score: \(gameModel.score). Repeat?")
                }
            )
    }

}

#Preview {
    GamePreview(target: .SwiftUI) { params in
        GameView(gameModel: params.gameModel)
    }
}
