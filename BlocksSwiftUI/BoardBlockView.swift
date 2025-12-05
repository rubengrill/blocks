//
//  BoardBlockView.swift
//  BlocksSwiftUI
//
//  Created by Ruben Grill on 11.04.23.
//

import BlocksEngine
import SwiftUI

struct BoardBlockView: View {

    var columns: Int
    var rows: Int
    var gridSize: CGSize
    var boardBlock: BoardBlock
    var isProjected = false

    var body: some View {
        let block = boardBlock.block
        let brickWidth = gridSize.width / CGFloat(columns)
        let brickHeight = gridSize.height / CGFloat(rows)
        let x = brickWidth * CGFloat(boardBlock.x)
        let y = brickHeight * CGFloat(boardBlock.y)
        let width = brickWidth * CGFloat(block.size)
        let height = brickHeight * CGFloat(block.size)

        BlockView(block: block, width: width, height: height)
            .offset(x: x, y: y)
            .frame(width: width, height: height)
            .frame(width: gridSize.width, height: gridSize.height, alignment: .topLeading)
            .opacity(isProjected ? 0.3 : 1)
            .animation(.easeIn(duration: 0.15), value: boardBlock.y)
            .id(boardBlock.id)
    }

}

#Preview("regular") {
    BoardBlockPreview { params in
        BoardBlockView(
            columns: 4,
            rows: 4,
            gridSize: params.gridSize,
            boardBlock: BoardBlock(blockShape: BlockShape.shapes[0], blockRotation: .clockwise0, x: 1, y: 0)
        )
    }
}

#Preview("projected") {
    BoardBlockPreview { params in
        BoardBlockView(
            columns: 4,
            rows: 4,
            gridSize: params.gridSize,
            boardBlock: BoardBlock(blockShape: BlockShape.shapes[0], blockRotation: .clockwise0, x: 1, y: 0),
            isProjected: true
        )
    }
}
