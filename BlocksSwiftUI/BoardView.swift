//
//  BoardView.swift
//  BlocksSwiftUI
//
//  Created by Ruben Grill on 08.04.23.
//

import SwiftUI

struct BoardView: View {

    @ObservedObject
    var gameModel: GameModel

    private var columns: Int { gameModel.game.board.columns }
    private var rows: Int { gameModel.game.board.rows }

    var body: some View {
        BoardGridView(columns: columns, rows: rows)
            .strokeBorder(.tint, lineWidth: 2)
            .aspectRatio(CGFloat(columns) / CGFloat(rows), contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    BoardBricksView(
                        gridSize: proxy.size,
                        bricks: gameModel.bricks
                    )

                    if gameModel.showProjectedBoardBlock, let boardBlock = gameModel.projectedBoardBlock {
                        BoardBlockView(
                            columns: columns,
                            rows: rows,
                            gridSize: proxy.size,
                            boardBlock: boardBlock,
                            isProjected: true
                        )
                    }

                    if let boardBlock = gameModel.currentBoardBlock {
                        BoardBlockView(
                            columns: columns,
                            rows: rows,
                            gridSize: proxy.size,
                            boardBlock: boardBlock
                        )
                    }

                    BoardGestureView(
                        columns: columns,
                        rows: rows,
                        gridSize: proxy.size,
                        moveLeft: gameModel.moveLeft,
                        moveRight: gameModel.moveRight,
                        moveDown: gameModel.moveDown,
                        moveToBottom: gameModel.moveToBottom,
                        rotateClockwise: gameModel.rotateClockwise
                    )
                }
            }
            .clipped()
    }

}

#Preview("Ratio") {
    BoardPreview.Ratio(target: .SwiftUI) { params in
        BoardView(gameModel: params.gameModel)
    }
}

#Preview("Size") {
    BoardPreview.Size(target: .SwiftUI) { params in
        BoardView(gameModel: params.gameModel)
    }
}

#Preview("Move") {
    BoardPreview.Move(target: .SwiftUI) { params in
        BoardView(gameModel: params.gameModel)
    }
}

#Preview("Clear") {
    BoardPreview.Clear(target: .SwiftUI) { params in
        BoardView(gameModel: params.gameModel)
    }
}
