//
//  BlockPreview.swift
//  Blocks
//
//  Created by Ruben Grill on 09.11.25.
//

import BlocksEngine
import SwiftUI

struct BlockPreviewParams {
    var block: Block
    var blockFrameSize: CGFloat
}

struct BlockPreview<Content: View>: View {

    @ViewBuilder
    var content: (BlockPreviewParams) -> Content

    @State
    private var blockShapeIndex = 0

    @State
    private var blockRotation: BlockRotation = .clockwise0

    var body: some View {
        let block = BlockShape.shapes[blockShapeIndex].getBlock(for: blockRotation)
        let blockWrapperFrameSize: CGFloat = 100
        let blockFrameSize = blockWrapperFrameSize / CGFloat(4) * CGFloat(block.size)

        VStack(spacing: 10) {
            Text(verbatim: "Block \(blockShapeIndex + 1) of \(BlockShape.shapes.count)")

            HStack {
                Button {
                    blockShapeIndex -= 1
                    blockRotation = .clockwise0
                } label: {
                    Image(systemName: "arrowshape.left").font(.largeTitle)
                }
                .disabled(blockShapeIndex == 0)

                Button {
                    blockShapeIndex += 1
                    blockRotation = .clockwise0
                } label: {
                    Image(systemName: "arrowshape.right").font(.largeTitle)
                }
                .disabled(blockShapeIndex == BlockShape.shapes.count - 1)
            }

            content(BlockPreviewParams(block: block, blockFrameSize: blockFrameSize))
                .frame(width: blockFrameSize, height: blockFrameSize)
                .frame(width: blockWrapperFrameSize, height: blockWrapperFrameSize)

            Button {
                blockRotation = blockRotation.rotateClockwise()
            } label: {
                Image(systemName: "rotate.right").font(.largeTitle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color("background"))
    }

}

#Preview {
    BlockPreview { _ in
        Text("content")
    }
}
