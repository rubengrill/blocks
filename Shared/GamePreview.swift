//
//  GamePreview.swift
//  Blocks
//
//  Created by Ruben Grill on 16.11.25.
//

import SwiftUI

struct GamePreviewParams {
    var gameModel: GameModel
}

struct GamePreview<Content: View>: View {

    var target: GameModel.Target
    var content: (GamePreviewParams) -> Content

    @StateObject
    private var gameModel: GameModel

    init(
        target: GameModel.Target,
        @ViewBuilder content: @escaping (GamePreviewParams) -> Content
    ) {
        self.target = target
        self.content = content
        self._gameModel = StateObject(wrappedValue: Self.createGameModel(target: target))
    }

    var body: some View {
        VStack(spacing: 10) {
            content(GamePreviewParams(gameModel: gameModel))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            HStack {
                Button(action: gameModel.start) {
                    Image(systemName: "play")
                }
                .disabled(gameModel.running)

                Button(action: gameModel.stop) {
                    Image(systemName: "stop")
                }
                .disabled(!gameModel.running)

                Button(action: gameModel.reset) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .font(.largeTitle)
        }
        .background(Color("background"))
    }

    private static func createGameModel(target: GameModel.Target) -> GameModel {
        let gameModel = GameModel(columns: 10, rows: 20, target: target)
        gameModel.showProjectedBoardBlock = true
        return gameModel
    }

}

#Preview {
    GamePreview(target: .none) { _ in
        Text("content")
    }
}
