//
//  BoardBricksView.swift
//  BlocksSwiftUI
//
//  Created by Ruben Grill on 11.04.23.
//

import BlocksEngine
import SwiftUI

struct BoardBricksView: View {

    var gridSize: CGSize
    var bricks: [[Brick?]]

    var body: some View {
        let rows = bricks.count
        let columns = bricks.first?.count ?? 0
        let brickWidth = gridSize.width / CGFloat(columns)
        let brickHeight = gridSize.height / CGFloat(rows)
        let bricksData: [(brick: Brick, x: Int, y: Int)] = (0 ..< columns * rows).compactMap { index in
            let x = index % columns
            let y = index / columns
            guard let brick = bricks[y][x] else { return nil }
            return (brick: brick, x: x, y: y)
        }

        Color.clear.overlay(alignment: .topLeading) {
            ForEach(bricksData, id: \.brick.id) { brickData in
                let x = brickWidth * CGFloat(brickData.x)
                let y = brickHeight * CGFloat(brickData.y)

                BrickView(backgroundColor: brickData.brick.blockForm.color)
                    .offset(x: x, y: y)
                    .frame(width: brickWidth, height: brickHeight)
                    // https://cubic-bezier.com/#.44,1.07,.09,-1.19
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .opacity.animation(.timingCurve(0.44, 1.07, 0.09, -1.19, duration: 0.4))
                    ))
                    .animation(.easeInOut(duration: 0.3).delay(0.4), value: brickData.y)
            }
        }
    }

}

#Preview {
    BoardBricksPreview { params in
        BoardBricksView(gridSize: params.gridSize, bricks: params.bricks)
    }
}
