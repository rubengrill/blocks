//
//  BoardPreview.swift
//  Blocks
//
//  Created by Ruben Grill on 09.11.25.
//

import BlocksEngine
import SwiftUI

struct BoardPreviewParams {
    var gameModel: GameModel
}

enum BoardPreview {

    // MARK: Ratio
    struct Ratio<Content: View>: View {

        var target: GameModel.Target
        var content: (BoardPreviewParams) -> Content

        @State
        private var width = 100.0

        @State
        private var height = 100.0

        @StateObject
        private var gameModel: GameModel

        init(
            target: GameModel.Target,
            @ViewBuilder content: @escaping (BoardPreviewParams) -> Content
        ) {
            self.target = target
            self.content = content
            self._gameModel = StateObject(wrappedValue: Self.createGameModel(target: target))
        }

        var body: some View {
            VStack {
                GeometryReader { proxy in
                    content(BoardPreviewParams(gameModel: gameModel))
                        .allowsHitTesting(false)
                        .frame(
                            width: proxy.size.width / 100 * width,
                            height: proxy.size.height / 100 * height
                        )
                        .background(.black, ignoresSafeAreaEdges: [])
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height / 2
                        )
                }

                Text(verbatim: "Width")
                Slider(value: $width, in: 0...100)

                Text(verbatim: "Height")
                Slider(value: $height, in: 0...100)
            }
            .background(Color("background"))
        }

        private static func createGameModel(target: GameModel.Target) -> GameModel {
            let gameModel = GameModel(columns: 10, rows: 20, target: target)
            try? gameModel.game.board.updateCurrentBoardBlock(BoardBlock(
                blockShape: BlockShape.shapes[0],
                blockRotation: .clockwise0,
                x: -1,
                y: 17
            ))
            try? gameModel.game.board.commitCurrentBoardBlock()
            try? gameModel.game.board.updateCurrentBoardBlock(BoardBlock(
                blockShape: BlockShape.shapes[0],
                blockRotation: .clockwise0,
                x: 3,
                y: 2
            ))
            gameModel.update()
            gameModel.showProjectedBoardBlock = true
            return gameModel
        }

    }

    // MARK: Size
    struct Size<Content: View>: View {

        var target: GameModel.Target
        var content: (BoardPreviewParams) -> Content

        @State
        private var gameModel: GameModel

        init(
            target: GameModel.Target,
            @ViewBuilder content: @escaping (BoardPreviewParams) -> Content
        ) {
            self.target = target
            self.content = content
            self._gameModel = State(initialValue: Self.createGameModel(columns: 10, rows: 20, target: target))
        }

        var body: some View {
            VStack {
                content(BoardPreviewParams(gameModel: gameModel))
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                HStack {
                    Text(verbatim: "\(gameModel.game.board.columns) columns")

                    Button(action: { changeColumns(offset: -1) }) {
                        Image(systemName: "minus").font(.largeTitle)
                    }
                    .disabled(gameModel.game.board.columns == 1)

                    Button(action: { changeColumns(offset: 1) }) {
                        Image(systemName: "plus").font(.largeTitle)
                    }
                    .disabled(gameModel.game.board.columns == 30)
                }

                HStack {
                    Text(verbatim: "\(gameModel.game.board.rows) rows")

                    Button(action: { changeRows(offset: -1) }) {
                        Image(systemName: "minus").font(.largeTitle)
                    }
                    .disabled(gameModel.game.board.rows == 1)

                    Button(action: { changeRows(offset: 1) }) {
                        Image(systemName: "plus").font(.largeTitle)
                    }
                    .disabled(gameModel.game.board.rows == 30)
                }
            }
            .background(Color("background"))
        }

        private static func createGameModel(columns: Int, rows: Int, target: GameModel.Target) -> GameModel {
            let gameModel = GameModel(columns: columns, rows: rows, target: target)
            try? gameModel.game.board.updateCurrentBoardBlock(BoardBlock(
                blockShape: BlockShape.shapes[0],
                blockRotation: .clockwise0,
                x: -1,
                y: 0
            ))
            gameModel.update()
            gameModel.showProjectedBoardBlock = true
            return gameModel
        }

        private func changeColumns(offset: Int) {
            let columns = gameModel.game.board.columns + offset
            let rows = gameModel.game.board.rows
            gameModel = Self.createGameModel(columns: columns, rows: rows, target: target)
        }

        private func changeRows(offset: Int) {
            let columns = gameModel.game.board.columns
            let rows = gameModel.game.board.rows + offset
            gameModel = Self.createGameModel(columns: columns, rows: rows, target: target)
        }

    }

    // MARK: Move
    struct Move<Content: View>: View {

        var target: GameModel.Target
        var content: (BoardPreviewParams) -> Content

        @StateObject
        private var gameModel: GameModel

        init(
            target: GameModel.Target,
            @ViewBuilder content: @escaping (BoardPreviewParams) -> Content
        ) {
            self.target = target
            self.content = content
            self._gameModel = StateObject(wrappedValue: Self.createGameModel(target: target))
        }

        var body: some View {
            VStack {
                content(BoardPreviewParams(gameModel: gameModel))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                HStack {
                    Button(action: gameModel.moveLeft) {
                        Image(systemName: "arrowshape.left")
                    }

                    Button(action: gameModel.moveRight) {
                        Image(systemName: "arrowshape.right")
                    }

                    Button(action: gameModel.moveDown) {
                        Image(systemName: "chevron.down")
                    }

                    Button(action: gameModel.moveToBottom) {
                        Image(systemName: "chevron.down.2")
                    }

                    Button(action: gameModel.rotateClockwise) {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button(action: gameModel.game.next) {
                        Text(verbatim: "Next")
                    }
                }
                .font(.largeTitle)
            }
            .background(Color("background"))
        }

        private static func createGameModel(target: GameModel.Target) -> GameModel {
            let gameModel = GameModel(columns: 10, rows: 20, target: target)
            try? gameModel.game.board.updateCurrentBoardBlock(BoardBlock(
                blockShape: BlockShape.shapes[0],
                blockRotation: .clockwise0,
                x: -1,
                y: 0
            ))
            gameModel.update()
            gameModel.showProjectedBoardBlock = true
            return gameModel
        }

    }

    // MARK: Clear
    struct Clear<Content: View>: View {

        var target: GameModel.Target
        var content: (BoardPreviewParams) -> Content

        @StateObject
        private var gameModel: GameModel

        init(
            target: GameModel.Target,
            @ViewBuilder content: @escaping (BoardPreviewParams) -> Content
        ) {
            self.target = target
            self.content = content
            self._gameModel = StateObject(wrappedValue: GameModel(columns: 3, rows: 6, target: target))
        }

        var body: some View {
            VStack {
                content(BoardPreviewParams(gameModel: gameModel))
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                HStack {
                    Button(action: clearFullRows) {
                        Image(systemName: "trash")
                    }
                    .disabled(!gameModel.game.board.canCommit)

                    Button(action: reset) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .font(.largeTitle)
            }
            .background(Color("background"))
            .onAppear(perform: reset)
        }

        private func clearFullRows() {
            gameModel.game.next()
        }

        private func reset() {
            gameModel.reset()
            try? gameModel.game.board.updateCurrentBoardBlock(BoardBlock(
                blockShape: BlockShape.shapes[2],
                blockRotation: .clockwise0,
                x: 0,
                y: 4
            ))
            try? gameModel.game.board.commitCurrentBoardBlock()
            try? gameModel.game.board.updateCurrentBoardBlock(BoardBlock(
                blockShape: BlockShape.shapes[3],
                blockRotation: .clockwise0,
                x: 1,
                y: 2
            ))
            gameModel.update()
        }

    }

}

#Preview("Ratio") {
    BoardPreview.Ratio(target: .none) { _ in
        Text("content")
            .foregroundStyle(.white)
    }
}

#Preview("Size") {
    BoardPreview.Size(target: .none) { _ in
        Text("content")
    }
}

#Preview("Move") {
    BoardPreview.Move(target: .none) { _ in
        Text("content")
    }
}

#Preview("Clear") {
    BoardPreview.Clear(target: .none) { _ in
        Text("content")
    }
}
