//
//  BlockView.swift
//  BlocksSwiftUI
//
//  Created by Ruben Grill on 08.04.23.
//

import BlocksEngine
import SwiftUI

struct BlockView: View {

    var block: Block
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        let size = block.size
        let brickWidth = width / CGFloat(size)
        let brickHeight = height / CGFloat(size)
        let bricksData: [(x: Int, y: Int)] = (0 ..< size * size).compactMap { index in
            let x = index % size
            let y = index / size
            guard block.data[y][x] > 0 else { return nil }
            return (x: x, y: y)
        }

        Color.clear.overlay(alignment: .topLeading) {
            ForEach(bricksData.indices, id: \.self) { index in
                let brickData = bricksData[index]
                let x = brickWidth * CGFloat(brickData.x)
                let y = brickHeight * CGFloat(brickData.y)

                BrickView(backgroundColor: block.blockForm.color)
                    .offset(x: x, y: y)
                    .frame(width: brickWidth, height: brickHeight)
            }
        }
    }

}

#Preview {
    BlockPreview { params in
        BlockView(block: params.block, width: params.blockFrameSize, height: params.blockFrameSize)
    }
}
