//
//  BoardGestureView.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 11.03.23.
//

import UIKit

class BoardGestureView: UIView {

    var columns: Int = 0
    var rows: Int = 0
    var moveLeft: (() -> Void)?
    var moveRight: (() -> Void)?
    var moveDown: (() -> Void)?
    var moveToBottom: (() -> Void)?
    var rotateClockwise: (() -> Void)?

    private var boardDragState: BoardDragState?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard columns > 0, rows > 0 else { return }
        guard let touch = touches.first else { return }

        let feedbackGenerator = UIImpactFeedbackGenerator()
        feedbackGenerator.prepare()

        boardDragState = BoardDragState(
            columns: columns,
            rows: rows,
            gridSize: bounds.size,
            startLocation: touch.location(in: self),
            startTimestamp: touch.timestamp,
            moveLeft: { self.moveLeft?() },
            moveRight: { self.moveRight?() },
            moveDown: { self.moveDown?() },
            moveToBottom: {
                self.moveToBottom?()
                feedbackGenerator.impactOccurred()
            },
            rotateClockwise: { self.rotateClockwise?() }
        )
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        boardDragState?.update(location: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        boardDragState?.end(timestamp: touches.first?.timestamp ?? 0)
        boardDragState = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        boardDragState = nil
    }

}
