//
//  BoardGestureView.swift
//  BlocksSwiftUI
//
//  Created by Ruben Grill on 11.04.23.
//

import SwiftUI

struct BoardGestureView: View {

    var columns: Int
    var rows: Int
    var gridSize: CGSize
    var moveLeft: () -> Void
    var moveRight: () -> Void
    var moveDown: () -> Void
    var moveToBottom: () -> Void
    var rotateClockwise: () -> Void

    @State
    private var boardDragState: BoardDragState?

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if boardDragState == nil {
                    let feedbackGenerator = UIImpactFeedbackGenerator()
                    feedbackGenerator.prepare()

                    boardDragState = BoardDragState(
                        columns: columns,
                        rows: rows,
                        gridSize: gridSize,
                        startLocation: value.startLocation,
                        startTimestamp: value.time.timeIntervalSince1970,
                        moveLeft: moveLeft,
                        moveRight: moveRight,
                        moveDown: moveDown,
                        moveToBottom: {
                            moveToBottom()
                            feedbackGenerator.impactOccurred()
                        },
                        rotateClockwise: rotateClockwise
                    )
                }

                boardDragState?.update(location: value.location)
            }
            .onEnded { value in
                boardDragState?.end(timestamp: value.time.timeIntervalSince1970)
                boardDragState = nil
            }
    }

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(dragGesture)
    }

}
