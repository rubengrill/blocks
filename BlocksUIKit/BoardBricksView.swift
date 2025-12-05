//
//  BoardBricksView.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 11.03.23.
//

import BlocksEngine
import SwiftUI
import UIKit

private struct BoardBrick {
    var brick: Brick
    var x: Int
    var y: Int
    var brickView: BrickView
    var gridGuideConstraints: [NSLayoutConstraint] = []
}

class BoardBricksView: UIView {

    var bricks: [[Brick?]] = [] {
        didSet {
            updateBricks()
        }
    }

    private var boardBricks: [Brick: BoardBrick] = [:]

    private lazy var gridGuide = GridGuide(view: self)

    private func updateBricks() {
        let rows = bricks.count
        let columns = bricks.first?.count ?? 0

        if columns != gridGuide.columns || rows != gridGuide.rows {
            subviews.forEach { $0.removeFromSuperview() }
            gridGuide.columns = columns
            gridGuide.rows = rows
            boardBricks = [:]
        }

        var newBoardBricks: [Brick: BoardBrick] = [:]
        var bricksAdded: [BoardBrick] = []
        var bricksMoved: [BoardBrick] = []
        var bricksCleared: [BoardBrick] = []

        for (y, row) in bricks.enumerated() {
            for (x, brick) in row.enumerated() {
                guard let brick else { continue }

                if var boardBrick = boardBricks[brick] {
                    if boardBrick.x != x || boardBrick.y != y {
                        boardBrick.x = x
                        boardBrick.y = y
                        bricksMoved.append(boardBrick)
                    }
                    newBoardBricks[brick] = boardBrick
                } else {
                    let brickView = BrickView()
                    brickView.translatesAutoresizingMaskIntoConstraints = false
                    brickView.backgroundColor = brick.blockForm.color
                    let boardBrick = BoardBrick(brick: brick, x: x, y: y, brickView: brickView)
                    bricksAdded.append(boardBrick)
                    newBoardBricks[brick] = boardBrick
                }
            }
        }

        for brick in Set(boardBricks.keys).subtracting(newBoardBricks.keys) {
            guard let boardBrick = boardBricks[brick] else { continue }
            bricksCleared.append(boardBrick)
        }

        boardBricks = newBoardBricks

        addBoardBricks(bricksAdded)
        moveBoardBricks(bricksMoved)
        clearBoardBricks(bricksCleared)
    }

    private func addBoardBricks(_ boardBricks: [BoardBrick]) {
        guard !boardBricks.isEmpty else { return }
        for boardBrick in boardBricks {
            var boardBrick = boardBrick
            addSubview(boardBrick.brickView)
            updateBoardBrickConstraints(&boardBrick)
            self.boardBricks[boardBrick.brick] = boardBrick
        }
    }

    private func moveBoardBricks(_ boardBricks: [BoardBrick]) {
        guard !boardBricks.isEmpty else { return }
        UIView.animate(withDuration: 0.3, delay: 0.4) {
            for boardBrick in boardBricks {
                var boardBrick = boardBrick
                self.updateBoardBrickConstraints(&boardBrick)
                self.boardBricks[boardBrick.brick] = boardBrick
            }
            self.layoutIfNeeded()
        }
    }

    private func clearBoardBricks(_ boardBricks: [BoardBrick]) {
        guard !boardBricks.isEmpty else { return }
        let views = boardBricks.map { $0.brickView }
        UIView.animateKeyframes(
            withDuration: 0.4,
            delay: 0,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2) { views.forEach { $0.alpha = 0.7 } }
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) { views.forEach { $0.alpha = 1 } }
                UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) { views.forEach { $0.alpha = 0 } }
            },
            completion: { _ in
                views.forEach { $0.removeFromSuperview() }
            }
        )
    }

    private func updateBoardBrickConstraints(_ boardBrick: inout BoardBrick) {
        let brickView = boardBrick.brickView
        let x = boardBrick.x
        let y = boardBrick.y

        NSLayoutConstraint.deactivate(boardBrick.gridGuideConstraints)

        boardBrick.gridGuideConstraints = [
            brickView.leftAnchor.constraint(equalTo: gridGuide.columnLayoutGuides[x].leftAnchor),
            brickView.rightAnchor.constraint(equalTo: gridGuide.columnLayoutGuides[x].rightAnchor),
            brickView.topAnchor.constraint(equalTo: gridGuide.rowLayoutGuides[y].topAnchor),
            brickView.bottomAnchor.constraint(equalTo: gridGuide.rowLayoutGuides[y].bottomAnchor),
        ]

        NSLayoutConstraint.activate(boardBrick.gridGuideConstraints)
    }

}

private struct BoardBricksViewRepresentable: UIViewRepresentable {

    var bricks: [[Brick?]]

    func makeUIView(context: Context) -> BoardBricksView {
        BoardBricksView()
    }

    func updateUIView(_ uiView: BoardBricksView, context: Context) {
        uiView.bricks = bricks
    }

}

#Preview {
    BoardBricksPreview { params in
        BoardBricksViewRepresentable(bricks: params.bricks)
    }
}
