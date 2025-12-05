//
//  GameModel.swift
//  Blocks
//
//  Created by Ruben Grill on 09.04.23.
//

import BlocksEngine
import SwiftUI
import UIKit

extension GameModel {

    enum Target {

        case SwiftUI
        case UIKit
        case none

        @MainActor
        func withFlushedTransaction(_ body: () -> Void) {
            switch self {
            case .SwiftUI:
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    body()
                }
            case .UIKit:
                UIView.setAnimationsEnabled(false)
                body()
                UIView.setAnimationsEnabled(true)
                CATransaction.flush()
            case .none:
                body()
            }
        }

        @MainActor
        func withCompletedTransaction(_ body: () -> Void) async {
            switch self {
            case .SwiftUI:
                await withCheckedContinuation { continuation in
                    var transaction = Transaction()
                    transaction.addAnimationCompletion {
                        continuation.resume()
                    }
                    withTransaction(transaction) {
                        body()
                    }
                }

            case.UIKit:
                await withCheckedContinuation { continuation in
                    CATransaction.setCompletionBlock {
                        continuation.resume()
                    }
                    body()
                }
            case .none:
                body()
            }
        }

    }

}

@MainActor
class GameModel: ObservableObject {

    let target: Target

    @Published
    private(set) var game: Game

    @Published
    private(set) var bricks: [[Brick?]]

    @Published
    private(set) var currentBoardBlock: BoardBlock?

    @Published
    private(set) var projectedBoardBlock: BoardBlock?

    @Published
    var showProjectedBoardBlock = false

    @Published
    private(set) var running = false

    @Published
    private(set) var isOver = false

    @Published
    private(set) var score = 0

    private var timeInterval: TimeInterval = initialTimeInterval
    private var timer: Timer?
    private var currentTask: Task<Void, Never>?

    private static let initialTimeInterval: TimeInterval = 0.5

    init(columns: Int, rows: Int, target: Target) {
        let game = Game(columns: columns, rows: rows)

        self.target = target
        self.game = game
        self.bricks = game.board.data
        self.currentBoardBlock = game.board.current
        self.projectedBoardBlock = game.board.projected

        game.delegate = self
    }

    func start() {
        guard !game.isOver, timer == nil else { return }
        scheduleNext()
        running = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        running = false
    }

    func reset() {
        stop()
        game = Game(columns: game.board.columns, rows: game.board.rows)
        game.delegate = self
        bricks = game.board.data
        currentBoardBlock = game.board.current
        projectedBoardBlock = game.board.projected
        isOver = false
        score = 0
        timeInterval = Self.initialTimeInterval
    }

    func update() {
        bricks = game.board.data
        currentBoardBlock = game.board.current
        projectedBoardBlock = game.board.projected
    }

    func moveLeft() {
        game.moveLeft()
    }

    func moveRight() {
        game.moveRight()
    }

    func moveDown() {
        game.moveDown()
    }

    func moveToBottom() {
        game.moveToBottom()
    }

    func rotateClockwise() {
        game.rotateClockwise()
    }

    private func scheduleNext() {
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [self] _ in
            MainActor.assumeIsolated {
                enqueueTask { [self] in
                    guard !game.isOver else { return }
                    game.next()
                    scheduleNext()
                }
            }
        }
    }

    private func enqueueTask(_ body: @escaping () async -> Void) {
        currentTask = Task { [currentTask] in
            await currentTask?.value
            await body()
        }
    }

}

extension GameModel: GameDelegate {

    func game(_ game: Game, newBlock action: NewBlockAction) {
        enqueueTask { [self] in
            target.withFlushedTransaction { // Properly animate NewBlockAction -> MoveBlockAction
                currentBoardBlock = action.boardBlock
                projectedBoardBlock = action.projectedBoardBlock
            }
        }
    }

    func game(_ game: Game, moveBlock action: MoveBlockAction) {
        enqueueTask { [self] in
            @MainActor
            func body() {
                currentBoardBlock = action.boardBlock
                projectedBoardBlock = action.projectedBoardBlock
            }
            if action.movedByGame, action.expectCommitAndClearFullRows {
                // Move with animation and wait for it to finish before starting clear full rows animation.
                await target.withCompletedTransaction(body)
            } else if action.movedByGame {
                // Move with animation but don't wait for it to finish, user should be able to move horizontally while animating.
                body()
            } else if action.movedToBottom {
                // Move with animation and wait for it to finish regardless of expectCommitAndClearFullRows.
                // - If expectCommitAndClearFullRows = true, we want the move animation to finish before starting the clear full rows animation.
                // - If expectCommitAndClearFullRows = false, there will still follow a commit (but no clear full rows),
                //   which will use withFlushedTransaction(), which would make this animation ineffective.
                //   Also, moveToBottom can happen just before next() and we want to wait for the animation to finish before the new block enters.
                await target.withCompletedTransaction(body)
            } else {
                // Don't animate when the user drags the block
                target.withFlushedTransaction(body)
            }
        }
    }

    func game(_ game: Game, commitBlock action: CommitBlockAction) {
        let data = game.board.data

        enqueueTask { [self] in
            target.withFlushedTransaction { // Properly animate CommitBlockAction -> ClearFullRowsAction
                currentBoardBlock = nil
                projectedBoardBlock = nil
                bricks = data
            }
        }
    }

    func game(_ game: Game, clearFullRows action: ClearFullRowsAction) {
        let data = game.board.data

        enqueueTask { [self] in
            // Animate and wait for it to finish before a new block enters.
            await target.withCompletedTransaction {
                bricks = data
            }
            score += action.fullRows.count
            timeInterval = max(0.1, timeInterval - 0.025)
        }
    }

    func game(_ game: Game, gameOver action: GameOverAction) {
        enqueueTask { [self] in
            stop()
            isOver = true
        }
    }

}
