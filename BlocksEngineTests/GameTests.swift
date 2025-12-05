//
//  GameTests.swift
//  BlocksEngineTests
//
//  Created by Ruben Grill on 09.03.23.
//

import XCTest

@testable import BlocksEngine

private let defaultBlockShape = BlockShape(blockForm: .O, data: [
    [0, 0, 0, 0],
    [0, 1, 1, 0],
    [0, 1, 1, 0],
    [0, 0, 0, 0],
])

private struct SameBlockIterator: IteratorProtocol {

    var blockShape = defaultBlockShape

    func next() -> BoardBlock? {
        BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 0)
    }

}

private enum AnyAction {

    case newBlock(NewBlockAction)
    case moveBlock(MoveBlockAction)
    case commitBlock(CommitBlockAction)
    case clearFullRows(ClearFullRowsAction)
    case gameOver(GameOverAction)

    var newBlockAction: NewBlockAction? { if case .newBlock(let action) = self { action } else { nil } }
    var moveBlockAction: MoveBlockAction? { if case .moveBlock(let action) = self { action } else { nil } }
    var commitBlockAction: CommitBlockAction? { if case .commitBlock(let action) = self { action } else { nil } }
    var clearFullRowsAction: ClearFullRowsAction? { if case .clearFullRows(let action) = self { action } else { nil } }
    var gameOverAction: GameOverAction? { if case .gameOver(let action) = self { action } else { nil } }

}

private final class GameEvents: GameDelegate {

    private var actions: [AnyAction] = []

    var count: Int { actions.count }

    // For more convenient access, but more importantly to avoid fatal errors in assertions:
    //
    // XCTAssertNotNil(gameEvents.actions[3].moveBlockAction)
    // ->
    // XCTAssertNotNil(gameEvents[3]?.moveBlockAction)
    subscript(index: Int) -> AnyAction? {
        guard index < actions.count else { return nil }
        return actions[index]
    }

    func game(_ game: Game, newBlock action: NewBlockAction) {
        actions.append(.newBlock(action))
    }

    func game(_ game: Game, moveBlock action: MoveBlockAction) {
        actions.append(.moveBlock(action))
    }

    func game(_ game: Game, commitBlock action: CommitBlockAction) {
        actions.append(.commitBlock(action))
    }

    func game(_ game: Game, clearFullRows action: ClearFullRowsAction) {
        actions.append(.clearFullRows(action))
    }

    func game(_ game: Game, gameOver action: GameOverAction) {
        actions.append(.gameOver(action))
    }

}

@MainActor
final class GameTests: XCTestCase {

    private lazy var gameEvents = GameEvents()
    private lazy var game: Game = {
        let result = Game(columns: 4, rows: 4)
        result.blocks = SameBlockIterator()
        result.delegate = gameEvents
        return result
    }()

    func testNewBlockIsPositionedAtCenterTopEnteringWithFirstRow() {
        game.next()

        XCTAssertEqual(game.board.current?.x, 0)
        XCTAssertEqual(game.board.current?.y, -2)
        XCTAssertFalse(game.isOver)
    }

    func testGameIsOverIfNewBlockCannotEnterBoard() {
        game.board.data = Array(Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        game.next()

        XCTAssertNil(game.board.current)
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        // Actions have no effect anymore
        game.next()
        game.moveLeft()
        game.moveRight()
        game.moveDown()
        game.moveToBottom()
        game.rotateClockwise()

        XCTAssertNil(game.board.current)
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    func testGameIsOverIfBlockCannotEnterFully() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()

        XCTAssertEqual(game.board.current?.x, 0)
        XCTAssertEqual(game.board.current?.y, -2)
        XCTAssertFalse(game.isOver)

        game.next() // Player had time until now to move the entering block

        XCTAssertNil(game.board.current)
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 1, 1, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))
    }

    func testGameIsOverIfBlockCannotEnterFullyWithMoveToBottom() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()

        XCTAssertFalse(game.isOver)

        game.moveToBottom()

        XCTAssertNil(game.board.current)
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 1, 1, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))
    }

    func testGameIsOverIfBlockCannotEnterFullyAndCannotMoveHorizontally() {
        game.board.data = Array(Bricks([
            [1, 0, 0, 1],
            [1, 1, 0, 1],
            [0, 1, 1, 1],
            [0, 1, 1, 0],
        ]))

        game.next()

        XCTAssertNil(game.board.current)
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [1, 1, 1, 1],
            [1, 1, 0, 1],
            [0, 1, 1, 1],
            [0, 1, 1, 0],
        ]))
    }

    func testMovingPossibleWhileBlockBoundsAtFilledSpace() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()
        game.moveRight()
        game.next()

        XCTAssertEqual(game.board.current?.x, 1)
        XCTAssertEqual(game.board.current?.y, -1)
        XCTAssertFalse(game.isOver)
    }

    func testMovingPossibleWhileBlockBoundsAtBottom() {
        game.next()
        game.next()
        game.next()
        game.next()

        XCTAssertEqual(game.board.current?.x, 0)
        XCTAssertEqual(game.board.current?.y, 1)
        XCTAssertFalse(game.isOver)

        game.moveRight()
        game.next()

        XCTAssertFalse(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 1, 1],
            [0, 0, 1, 1],
        ]))
    }

    func testClearsFullRowsImmediately() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()
        game.moveRight()
        game.next()
        game.next()
        game.next() // Moving horizontally not possible, can commit & clear immediately

        XCTAssertFalse(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 1, 0, 0],
        ]))
    }

    func testMoveToBottom() {
        game.next()
        game.moveToBottom()

        XCTAssertFalse(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    func testMoveToBottomCommitsImmediately() {
        game.next()
        game.next()
        game.next()
        game.next()

        XCTAssertEqual(game.board.current?.x, 0)
        XCTAssertEqual(game.board.current?.y, 1)
        XCTAssertFalse(game.isOver)

        game.moveToBottom() // Without moveToBottom, the player could still move the block horizontally

        XCTAssertFalse(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    func testMoveToBottomClearsFullRowsImmediately() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
        ]))

        game.next()
        game.moveToBottom()

        XCTAssertFalse(game.isOver)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 0, 0, 1],
        ]))
    }

    func testMoveDown() {
        game.next()

        for _ in 1...10 {
            game.moveDown() // Once block can't move down anymore, it has no effect
        }

        XCTAssertEqual(game.board.current?.x, 0)
        XCTAssertEqual(game.board.current?.y, 1)
        XCTAssertFalse(game.isOver)
    }

    func testMoveLeft() {
        game.next()

        for _ in 1...10 {
            game.moveLeft() // Once block can't move left anymore, it has no effect
        }

        XCTAssertEqual(game.board.current?.x, -1)
        XCTAssertEqual(game.board.current?.y, -2)
        XCTAssertFalse(game.isOver)
    }

    func testMoveRight() {
        game.next()

        for _ in 1...10 {
            game.moveRight() // Once block can't move right anymore, it has no effect
        }

        XCTAssertEqual(game.board.current?.x, 1)
        XCTAssertEqual(game.board.current?.y, -2)
        XCTAssertFalse(game.isOver)
    }

    func testRotateClockwise() throws {
        let blockShape = BlockShape(blockForm: .L, data: [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ])
        game.blocks = SameBlockIterator(blockShape: blockShape)

        game.next()

        XCTAssertEqual(Bricks(try XCTUnwrap(game.board.current).block.data), Bricks([
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ]))

        game.rotateClockwise()

        XCTAssertEqual(Bricks(try XCTUnwrap(game.board.current).block.data), Bricks([
            [0, 0, 0],
            [1, 1, 1],
            [1, 0, 0],
        ]))

        game.rotateClockwise()

        XCTAssertEqual(Bricks(try XCTUnwrap(game.board.current).block.data), Bricks([
            [1, 1, 0],
            [0, 1, 0],
            [0, 1, 0],
        ]))

        game.rotateClockwise()

        XCTAssertEqual(Bricks(try XCTUnwrap(game.board.current).block.data), Bricks([
            [0, 0, 1],
            [1, 1, 1],
            [0, 0, 0],
        ]))

        game.rotateClockwise()

        XCTAssertEqual(Bricks(try XCTUnwrap(game.board.current).block.data), Bricks([
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ]))
    }

    func testRotateClockwiseMovesHorizontallyToSucceed() {
        let blockShape = BlockShape(blockForm: .L, data: [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ])
        game.blocks = SameBlockIterator(blockShape: blockShape)
        game.board.data = Array(Bricks([
            [1, 0, 0, 0],
            [1, 0, 0, 0],
            [1, 0, 0, 0],
            [1, 0, 0, 0],
        ]))

        game.next()
        game.next()
        game.next()

        XCTAssertEqual(game.board.current?.x, 0)
        XCTAssertEqual(game.board.current?.y, 0)

        game.rotateClockwise()

        XCTAssertEqual(game.board.current?.x, 1)
        XCTAssertEqual(game.board.current?.y, 0)

        game.rotateClockwise()

        XCTAssertEqual(game.board.current?.x, 1)
        XCTAssertEqual(game.board.current?.y, 0)

        game.board.data = Array(Bricks([
            [0, 0, 0, 1],
            [0, 0, 0, 1],
            [0, 0, 0, 1],
            [0, 0, 0, 1],
        ]))

        game.rotateClockwise()

        XCTAssertEqual(game.board.current?.x, 0)
        XCTAssertEqual(game.board.current?.y, 0)
    }

    func testBlocksAreRandom() throws {
        var blockShapes = Set<ObjectIdentifier>()
        var blockRotations = Set<BlockRotation>()

        for _ in 1 ... 10 {
            let game = Game(columns: 4, rows: 4)
            game.next()
            let boardBlock = try XCTUnwrap(game.board.current)
            blockShapes.insert(ObjectIdentifier(boardBlock.blockShape.blockClockwise0))
            blockRotations.insert(boardBlock.blockRotation)
        }

        XCTAssertTrue(blockShapes.count > 1)
        XCTAssertTrue(blockRotations.count > 1)
    }

    func testDelegate() throws {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 1, 1],
        ]))

        XCTAssertEqual(gameEvents.count, 0)

        game.next()

        let firstBoardBlock = try XCTUnwrap(game.board.current)

        XCTAssertEqual(gameEvents.count, 2)
        XCTAssertNotNil(gameEvents[0]?.newBlockAction)
        XCTAssertEqual(gameEvents[0]?.newBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[0]?.newBlockAction?.boardBlock.x, 0)
        XCTAssertEqual(gameEvents[0]?.newBlockAction?.boardBlock.y, -3)
        XCTAssertNotNil(gameEvents[1]?.moveBlockAction)
        XCTAssertEqual(gameEvents[1]?.moveBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[1]?.moveBlockAction?.boardBlock.x, 0)
        XCTAssertEqual(gameEvents[1]?.moveBlockAction?.boardBlock.y, -2)
        XCTAssertEqual(gameEvents[1]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[1]?.moveBlockAction?.movedByGame, true)
        XCTAssertEqual(gameEvents[1]?.moveBlockAction?.expectCommitAndClearFullRows, false)

        game.next()

        XCTAssertEqual(gameEvents.count, 3)
        XCTAssertNotNil(gameEvents[2]?.moveBlockAction)
        XCTAssertEqual(gameEvents[2]?.moveBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[2]?.moveBlockAction?.boardBlock.x, 0)
        XCTAssertEqual(gameEvents[2]?.moveBlockAction?.boardBlock.y, -1)
        XCTAssertEqual(gameEvents[2]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[2]?.moveBlockAction?.movedByGame, true)
        XCTAssertEqual(gameEvents[2]?.moveBlockAction?.expectCommitAndClearFullRows, false)

        game.moveLeft()

        XCTAssertEqual(gameEvents.count, 4)
        XCTAssertNotNil(gameEvents[3]?.moveBlockAction)
        XCTAssertEqual(gameEvents[3]?.moveBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[3]?.moveBlockAction?.boardBlock.x, -1)
        XCTAssertEqual(gameEvents[3]?.moveBlockAction?.boardBlock.y, -1)
        XCTAssertEqual(gameEvents[3]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[3]?.moveBlockAction?.movedByGame, false)
        XCTAssertEqual(gameEvents[3]?.moveBlockAction?.expectCommitAndClearFullRows, false)

        game.moveLeft() // move left not possible

        XCTAssertEqual(gameEvents.count, 4)

        game.moveDown()

        XCTAssertEqual(gameEvents.count, 5)
        XCTAssertNotNil(gameEvents[4]?.moveBlockAction)
        XCTAssertEqual(gameEvents[4]?.moveBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[4]?.moveBlockAction?.boardBlock.x, -1)
        XCTAssertEqual(gameEvents[4]?.moveBlockAction?.boardBlock.y, 0)
        XCTAssertEqual(gameEvents[4]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[4]?.moveBlockAction?.movedByGame, false)
        XCTAssertEqual(gameEvents[4]?.moveBlockAction?.expectCommitAndClearFullRows, false)

        game.rotateClockwise()

        XCTAssertEqual(gameEvents.count, 6)
        XCTAssertNotNil(gameEvents[5]?.moveBlockAction)
        XCTAssertEqual(gameEvents[5]?.moveBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[5]?.moveBlockAction?.boardBlock.x, -1)
        XCTAssertEqual(gameEvents[5]?.moveBlockAction?.boardBlock.y, 0)
        XCTAssertEqual(gameEvents[5]?.moveBlockAction?.boardBlock.blockRotation, .clockwise90)
        XCTAssertEqual(gameEvents[5]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[5]?.moveBlockAction?.movedByGame, false)
        XCTAssertEqual(gameEvents[5]?.moveBlockAction?.expectCommitAndClearFullRows, false)

        game.moveDown()

        XCTAssertEqual(gameEvents.count, 9)
        XCTAssertNotNil(gameEvents[6]?.moveBlockAction)
        XCTAssertEqual(gameEvents[6]?.moveBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[6]?.moveBlockAction?.boardBlock.x, -1)
        XCTAssertEqual(gameEvents[6]?.moveBlockAction?.boardBlock.y, 1)
        XCTAssertEqual(gameEvents[6]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[6]?.moveBlockAction?.movedByGame, false)
        XCTAssertEqual(gameEvents[6]?.moveBlockAction?.expectCommitAndClearFullRows, true)
        XCTAssertNotNil(gameEvents[7]?.commitBlockAction)
        XCTAssertEqual(gameEvents[7]?.commitBlockAction?.boardBlock.id, firstBoardBlock.id)
        XCTAssertEqual(gameEvents[7]?.commitBlockAction?.boardBlock.x, -1)
        XCTAssertEqual(gameEvents[7]?.commitBlockAction?.boardBlock.y, 1)
        XCTAssertNotNil(gameEvents[8]?.clearFullRowsAction)
        XCTAssertEqual(gameEvents[8]?.clearFullRowsAction?.fullRows, [3])

        game.moveDown() // move down not possible

        XCTAssertEqual(gameEvents.count, 9)
        XCTAssertEqual(Bricks(game.board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()

        let secondBoardBlock = try XCTUnwrap(game.board.current)

        XCTAssertNotEqual(firstBoardBlock.id, secondBoardBlock.id)
        XCTAssertEqual(gameEvents.count, 11)
        XCTAssertNotNil(gameEvents[9]?.newBlockAction)
        XCTAssertEqual(gameEvents[9]?.newBlockAction?.boardBlock.id, secondBoardBlock.id)
        XCTAssertEqual(gameEvents[9]?.newBlockAction?.boardBlock.x, 0)
        XCTAssertEqual(gameEvents[9]?.newBlockAction?.boardBlock.y, -3)
        XCTAssertNotNil(gameEvents[10]?.moveBlockAction)
        XCTAssertEqual(gameEvents[10]?.moveBlockAction?.boardBlock.id, secondBoardBlock.id)
        XCTAssertEqual(gameEvents[10]?.moveBlockAction?.boardBlock.x, 0)
        XCTAssertEqual(gameEvents[10]?.moveBlockAction?.boardBlock.y, -2)
        XCTAssertEqual(gameEvents[10]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[10]?.moveBlockAction?.movedByGame, true)
        XCTAssertEqual(gameEvents[10]?.moveBlockAction?.expectCommitAndClearFullRows, false)

        game.moveRight()

        XCTAssertEqual(gameEvents.count, 12)
        XCTAssertNotNil(gameEvents[11]?.moveBlockAction)
        XCTAssertEqual(gameEvents[11]?.moveBlockAction?.boardBlock.id, secondBoardBlock.id)
        XCTAssertEqual(gameEvents[11]?.moveBlockAction?.boardBlock.x, 1)
        XCTAssertEqual(gameEvents[11]?.moveBlockAction?.boardBlock.y, -2)
        XCTAssertEqual(gameEvents[11]?.moveBlockAction?.movedToBottom, false)
        XCTAssertEqual(gameEvents[11]?.moveBlockAction?.movedByGame, false)
        XCTAssertEqual(gameEvents[11]?.moveBlockAction?.expectCommitAndClearFullRows, false)

        game.moveRight() // move right not possible

        XCTAssertEqual(gameEvents.count, 12)

        game.moveToBottom()

        XCTAssertEqual(gameEvents.count, 15)
        XCTAssertNotNil(gameEvents[12]?.moveBlockAction)
        XCTAssertEqual(gameEvents[12]?.moveBlockAction?.boardBlock.id, secondBoardBlock.id)
        XCTAssertEqual(gameEvents[12]?.moveBlockAction?.boardBlock.x, 1)
        XCTAssertEqual(gameEvents[12]?.moveBlockAction?.boardBlock.y, 1)
        XCTAssertEqual(gameEvents[12]?.moveBlockAction?.movedToBottom, true)
        XCTAssertEqual(gameEvents[12]?.moveBlockAction?.movedByGame, false)
        XCTAssertEqual(gameEvents[12]?.moveBlockAction?.expectCommitAndClearFullRows, true)
        XCTAssertNotNil(gameEvents[13]?.commitBlockAction)
        XCTAssertEqual(gameEvents[13]?.commitBlockAction?.boardBlock.id, secondBoardBlock.id)
        XCTAssertEqual(gameEvents[13]?.commitBlockAction?.boardBlock.x, 1)
        XCTAssertEqual(gameEvents[13]?.commitBlockAction?.boardBlock.y, 1)
        XCTAssertNotNil(gameEvents[14]?.clearFullRowsAction)
        XCTAssertEqual(gameEvents[14]?.clearFullRowsAction?.fullRows, [3])
    }

    // When only using the Game API, clear full rows happens always when the block moves down.
    // But when using the Board API directly, edge cases are possible,
    // where clear full rows need to happen without movement.
    func testClearFullRowsEdgeCases() throws {
        for gameMethod in [game.next, game.moveToBottom] {
            game.board.data = Array(Bricks([
                [0, 0, 0, 0],
                [1, 1, 0, 0],
                [1, 1, 0, 0],
                [1, 1, 0, 0],
            ]))

            game.next()

            var boardBlock = try XCTUnwrap(game.board.current)
            boardBlock.x = 1
            boardBlock.y = 1
            try game.board.updateCurrentBoardBlock(boardBlock)

            gameMethod()

            XCTAssertNil(game.board.current)
            XCTAssertFalse(game.isOver)
            XCTAssertEqual(Bricks(game.board.data), Bricks([
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [1, 1, 0, 0],
            ]))
        }
    }

}
