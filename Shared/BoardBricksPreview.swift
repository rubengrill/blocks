//
//  BoardBricksPreview.swift
//  Blocks
//
//  Created by Ruben Grill on 10.11.25.
//

import BlocksEngine
import SwiftUI

struct BoardBricksPreviewParams {
    var bricks: [[Brick?]]
    var gridSize: CGSize
}

struct BoardBricksPreview<Content: View>: View {

    @ViewBuilder
    var content: (BoardBricksPreviewParams) -> Content

    @State
    private var bricks: [[Brick?]] = initialBricks

    @State
    private var canClearFullRows = true

    private let gridSize = CGSize(width: 300, height: 300)

    private static var initialBricks: [[Brick?]] {
        [
            [nil, nil, nil],
            [nil, Brick(blockForm: .T), nil],
            [Brick(blockForm: .T), Brick(blockForm: .T), Brick(blockForm: .T)],
        ]
    }

    var body: some View {
        VStack {
            content(BoardBricksPreviewParams(bricks: bricks, gridSize: gridSize))
                .frame(width: gridSize.width, height: gridSize.height)
                .overlay {
                    Rectangle()
                        .strokeBorder(.tint, lineWidth: 2)
                }

            HStack {
                Button {
                    bricks = [
                        [nil, nil, nil],
                        [nil, nil, nil],
                        bricks[1],
                    ]
                    canClearFullRows = false
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(!canClearFullRows)

                Button {
                    bricks = Self.initialBricks
                    canClearFullRows = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .font(.largeTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color("background"))
    }

}

#Preview {
    BoardBricksPreview { _ in
        Text("content")
    }
}
