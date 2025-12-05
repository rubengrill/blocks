//
//  BoardDragState.swift
//  Blocks
//
//  Created by Ruben Grill on 09.04.23.
//

import Foundation

@MainActor
struct BoardDragState {

    let columns: Int
    let rows: Int
    let gridSize: CGSize
    let startLocation: CGPoint
    let startTimestamp: TimeInterval
    let moveLeft: () -> Void
    let moveRight: () -> Void
    let moveDown: () -> Void
    let moveToBottom: () -> Void
    let rotateClockwise: () -> Void

    private var referenceLocation: CGPoint = .zero
    private var previousLocation: CGPoint?
    private var previousDeltaX: CGFloat?
    private var previousDeltaY: CGFloat?
    private var moved = false
    private var completed = false

    init(
        columns: Int,
        rows: Int,
        gridSize: CGSize,
        startLocation: CGPoint,
        startTimestamp: TimeInterval,
        moveLeft: @escaping () -> Void,
        moveRight: @escaping () -> Void,
        moveDown: @escaping () -> Void,
        moveToBottom: @escaping () -> Void,
        rotateClockwise: @escaping () -> Void
    ) {
        self.columns = columns
        self.rows = rows
        self.gridSize = gridSize
        self.startLocation = startLocation
        self.startTimestamp = startTimestamp
        self.moveLeft = Self.moveAsync(moveLeft)
        self.moveRight = Self.moveAsync(moveRight)
        self.moveDown = Self.moveAsync(moveDown)
        self.moveToBottom = Self.moveAsync(moveToBottom)
        self.rotateClockwise = Self.moveAsync(rotateClockwise)
    }

    mutating func update(location: CGPoint) {
        guard !completed else { return }
        guard columns > 0, rows > 0 else { return }
        guard gridSize.width > 0, gridSize.height > 0 else { return }

        let deltaX = location.x - (previousLocation ?? startLocation).x
        let deltaY = location.y - (previousLocation ?? startLocation).y

        guard deltaX != 0 || deltaY != 0 else { return }

        if let previousLocation, let previousDeltaX, let previousDeltaY {
            if deltaX > 0 && previousDeltaX < 0 || deltaX < 0 && previousDeltaX > 0 {
                referenceLocation.x = previousLocation.x
            }
            if deltaY > 0 && previousDeltaY < 0 || deltaY < 0 && previousDeltaY > 0 {
                referenceLocation.y = previousLocation.y
            }
        } else {
            referenceLocation = startLocation
        }

        let referenceDeltaX = location.x - referenceLocation.x
        let referenceDeltaY = location.y - referenceLocation.y
        let moveWidth = gridSize.width / CGFloat(columns) * 0.5 // Horizontally it should move quicker
        let moveHeight = gridSize.height / CGFloat(rows)
        let moveX = Int(referenceDeltaX / moveWidth)
        let moveY = Int(referenceDeltaY / moveHeight)

        guard moveY > -2 else {
            moveToBottom()
            moved = true
            completed = true
            return
        }

        if moveY > 0 {
            for _ in 0 ..< moveY {
                moveDown()
                moved = true
            }

            referenceLocation.y += CGFloat(moveY) * moveHeight
        }

        if moveX != 0 {
            for _ in 0 ..< abs(moveX) {
                if moveX < 0 {
                    moveLeft()
                    moved = true
                } else {
                    moveRight()
                    moved = true
                }
            }

            referenceLocation.x += CGFloat(moveX) * moveWidth
        }

        previousLocation = location
        previousDeltaX = deltaX
        previousDeltaY = deltaY
    }

    mutating func end(timestamp: TimeInterval) {
        guard !completed else { return }

        if !moved, timestamp - startTimestamp < 0.2 {
            rotateClockwise()
        }

        completed = true
    }

    private static func moveAsync(_ move: @escaping () -> Void) -> () -> Void {
        {
            Task { @MainActor in
                move()
            }
        }
    }

}
