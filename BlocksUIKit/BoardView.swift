//
//  BoardView.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 11.03.23.
//

import Combine
import SwiftUI
import UIKit

class BoardView: UIView {

    var gameModel: GameModel? { didSet { updateGameModel() } }

    private var columns: Int { gameModel?.game.board.columns ?? 0 }
    private var rows: Int { gameModel?.game.board.rows ?? 0 }

    private let boardGridView = BoardGridView()
    private let boardBricksView = BoardBricksView()
    private let boardBlockView = BoardBlockView()
    private let boardGestureView = BoardGestureView()
    private let projectedBoardBlockView = BoardBlockView()

    private var ratioConstraint: NSLayoutConstraint?
    private var gameModelCancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)

        boardGridView.translatesAutoresizingMaskIntoConstraints = false
        boardGridView.clipsToBounds = true

        // Translate frame set in layoutSubviews() into constraints automatically
        boardBricksView.translatesAutoresizingMaskIntoConstraints = true
        boardBlockView.translatesAutoresizingMaskIntoConstraints = true
        boardGestureView.translatesAutoresizingMaskIntoConstraints = true
        projectedBoardBlockView.translatesAutoresizingMaskIntoConstraints = true

        addSubview(boardGridView)

        let widthConstraint = boardGridView.widthAnchor.constraint(equalTo: widthAnchor)
        widthConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            widthConstraint,
            boardGridView.centerXAnchor.constraint(equalTo: centerXAnchor),
            boardGridView.centerYAnchor.constraint(equalTo: centerYAnchor),
            boardGridView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            boardGridView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor),
        ])

        boardGridView.addSubview(boardBricksView)
        boardGridView.addSubview(projectedBoardBlockView)
        boardGridView.addSubview(boardBlockView)
        boardGridView.addSubview(boardGestureView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        boardBricksView.frame = boardGridView.bounds
        boardBlockView.frame = boardGridView.bounds
        boardGestureView.frame = boardGridView.bounds
        projectedBoardBlockView.frame = boardGridView.bounds
    }

    private func updateGameModel() {
        gameModelCancellables.removeAll()

        boardGridView.columns = columns
        boardGridView.rows = rows

        boardBlockView.columns = columns
        boardBlockView.rows = rows

        boardGestureView.columns = columns
        boardGestureView.rows = rows
        boardGestureView.moveLeft = gameModel?.moveLeft
        boardGestureView.moveRight = gameModel?.moveRight
        boardGestureView.moveDown = gameModel?.moveDown
        boardGestureView.moveToBottom = gameModel?.moveToBottom
        boardGestureView.rotateClockwise = gameModel?.rotateClockwise

        projectedBoardBlockView.columns = columns
        projectedBoardBlockView.rows = rows
        projectedBoardBlockView.isProjected = true
        projectedBoardBlockView.isHidden = !(gameModel?.showProjectedBoardBlock ?? false)

        updateRatioConstraint()

        guard let gameModel else { return }

        gameModel.$bricks
            .assign(to: \.boardBricksView.bricks, on: self)
            .store(in: &gameModelCancellables)

        gameModel.$currentBoardBlock
            .assign(to: \.boardBlockView.boardBlock, on: self)
            .store(in: &gameModelCancellables)

        gameModel.$projectedBoardBlock
            .assign(to: \.projectedBoardBlockView.boardBlock, on: self)
            .store(in: &gameModelCancellables)
    }

    private func updateRatioConstraint() {
        ratioConstraint?.isActive = false
        guard columns > 0, rows > 0 else { return }
        let ratio = CGFloat(columns) / CGFloat(rows)
        ratioConstraint = boardGridView.widthAnchor.constraint(equalTo: boardGridView.heightAnchor, multiplier: ratio)
        ratioConstraint?.isActive = true
    }

}

private struct BoardViewRepresentable: UIViewRepresentable {

    var gameModel: GameModel

    func makeUIView(context: Context) -> BoardView {
        BoardView()
    }

    func updateUIView(_ uiView: BoardView, context: Context) {
        uiView.gameModel = gameModel
    }

}

#Preview("Ratio") {
    BoardPreview.Ratio(target: .UIKit) { params in
        BoardViewRepresentable(gameModel: params.gameModel)
    }
}

#Preview("Size") {
    BoardPreview.Size(target: .UIKit) { params in
        BoardViewRepresentable(gameModel: params.gameModel)
    }
}

#Preview("Move") {
    BoardPreview.Move(target: .UIKit) { params in
        BoardViewRepresentable(gameModel: params.gameModel)
    }
}

#Preview("Clear") {
    BoardPreview.Clear(target: .UIKit) { params in
        BoardViewRepresentable(gameModel: params.gameModel)
    }
}
