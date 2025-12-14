//
//  GameTests.swift
//  BlocksEngineTests
//
//  Created by Ruben Grill on 09.03.23.
//

import Testing

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
@Suite
struct GameTests {

    private lazy var gameEvents = GameEvents()
    private lazy var game: Game = {
        let result = Game(columns: 4, rows: 4)
        result.blocks = SameBlockIterator()
        result.delegate = gameEvents
        return result
    }()

    @Test
    mutating func testNewBlockIsPositionedAtCenterTopEnteringWithFirstRow() {
        game.next()

        #expect(game.board.current?.x == 0)
        #expect(game.board.current?.y == -2)
        #expect(!game.isOver)
    }

    @Test
    mutating func testGameIsOverIfNewBlockCannotEnterBoard() {
        game.board.data = Array(Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        game.next()

        #expect(game.board.current == nil)
        #expect(game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
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

        #expect(game.board.current == nil)
        #expect(game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    @Test
    mutating func testGameIsOverIfBlockCannotEnterFully() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()

        #expect(game.board.current?.x == 0)
        #expect(game.board.current?.y == -2)
        #expect(!game.isOver)

        game.next() // Player had time until now to move the entering block

        #expect(game.board.current == nil)
        #expect(game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 1, 1, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))
    }

    @Test
    mutating func testGameIsOverIfBlockCannotEnterFullyWithMoveToBottom() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()

        #expect(!game.isOver)

        game.moveToBottom()

        #expect(game.board.current == nil)
        #expect(game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 1, 1, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))
    }

    @Test
    mutating func testGameIsOverIfBlockCannotEnterFullyAndCannotMoveHorizontally() {
        game.board.data = Array(Bricks([
            [1, 0, 0, 1],
            [1, 1, 0, 1],
            [0, 1, 1, 1],
            [0, 1, 1, 0],
        ]))

        game.next()

        #expect(game.board.current == nil)
        #expect(game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [1, 1, 1, 1],
            [1, 1, 0, 1],
            [0, 1, 1, 1],
            [0, 1, 1, 0],
        ]))
    }

    @Test
    mutating func testMovingPossibleWhileBlockBoundsAtFilledSpace() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()
        game.moveRight()
        game.next()

        #expect(game.board.current?.x == 1)
        #expect(game.board.current?.y == -1)
        #expect(!game.isOver)
    }

    @Test
    mutating func testMovingPossibleWhileBlockBoundsAtBottom() {
        game.next()
        game.next()
        game.next()
        game.next()

        #expect(game.board.current?.x == 0)
        #expect(game.board.current?.y == 1)
        #expect(!game.isOver)

        game.moveRight()
        game.next()

        #expect(!game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 1, 1],
            [0, 0, 1, 1],
        ]))
    }

    @Test
    mutating func testClearsFullRowsImmediately() {
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

        #expect(!game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 1, 0, 0],
        ]))
    }

    @Test
    mutating func testMoveToBottom() {
        game.next()
        game.moveToBottom()

        #expect(!game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    @Test
    mutating func testMoveToBottomCommitsImmediately() {
        game.next()
        game.next()
        game.next()
        game.next()

        #expect(game.board.current?.x == 0)
        #expect(game.board.current?.y == 1)
        #expect(!game.isOver)

        game.moveToBottom() // Without moveToBottom, the player could still move the block horizontally

        #expect(!game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    @Test
    mutating func testMoveToBottomClearsFullRowsImmediately() {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
        ]))

        game.next()
        game.moveToBottom()

        #expect(!game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 0, 0, 1],
        ]))
    }

    @Test
    mutating func testMoveDown() {
        game.next()

        for _ in 1...10 {
            game.moveDown() // Once block can't move down anymore, it has no effect
        }

        #expect(game.board.current?.x == 0)
        #expect(game.board.current?.y == 1)
        #expect(!game.isOver)
    }

    @Test
    mutating func testMoveLeft() {
        game.next()

        for _ in 1...10 {
            game.moveLeft() // Once block can't move left anymore, it has no effect
        }

        #expect(game.board.current?.x == -1)
        #expect(game.board.current?.y == -2)
        #expect(!game.isOver)
    }

    @Test
    mutating func testMoveRight() {
        game.next()

        for _ in 1...10 {
            game.moveRight() // Once block can't move right anymore, it has no effect
        }

        #expect(game.board.current?.x == 1)
        #expect(game.board.current?.y == -2)
        #expect(!game.isOver)
    }

    @Test
    mutating func testRotateClockwise() throws {
        let blockShape = BlockShape(blockForm: .L, data: [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ])
        game.blocks = SameBlockIterator(blockShape: blockShape)

        game.next()

        #expect(Bricks(try #require(game.board.current).block.data) == Bricks([
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ]))

        game.rotateClockwise()

        #expect(Bricks(try #require(game.board.current).block.data) == Bricks([
            [0, 0, 0],
            [1, 1, 1],
            [1, 0, 0],
        ]))

        game.rotateClockwise()

        #expect(Bricks(try #require(game.board.current).block.data) == Bricks([
            [1, 1, 0],
            [0, 1, 0],
            [0, 1, 0],
        ]))

        game.rotateClockwise()

        #expect(Bricks(try #require(game.board.current).block.data) == Bricks([
            [0, 0, 1],
            [1, 1, 1],
            [0, 0, 0],
        ]))

        game.rotateClockwise()

        #expect(Bricks(try #require(game.board.current).block.data) == Bricks([
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ]))
    }

    @Test
    mutating func testRotateClockwiseMovesHorizontallyToSucceed() {
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

        #expect(game.board.current?.x == 0)
        #expect(game.board.current?.y == 0)

        game.rotateClockwise()

        #expect(game.board.current?.x == 1)
        #expect(game.board.current?.y == 0)

        game.rotateClockwise()

        #expect(game.board.current?.x == 1)
        #expect(game.board.current?.y == 0)

        game.board.data = Array(Bricks([
            [0, 0, 0, 1],
            [0, 0, 0, 1],
            [0, 0, 0, 1],
            [0, 0, 0, 1],
        ]))

        game.rotateClockwise()

        #expect(game.board.current?.x == 0)
        #expect(game.board.current?.y == 0)
    }

    @Test
    mutating func testBlocksAreRandom() throws {
        var blockShapes = Set<ObjectIdentifier>()
        var blockRotations = Set<BlockRotation>()

        for _ in 1 ... 10 {
            let game = Game(columns: 4, rows: 4)
            game.next()
            let boardBlock = try #require(game.board.current)
            blockShapes.insert(ObjectIdentifier(boardBlock.blockShape.blockClockwise0))
            blockRotations.insert(boardBlock.blockRotation)
        }

        #expect(blockShapes.count > 1)
        #expect(blockRotations.count > 1)
    }

    @Test
    mutating func testDelegate() throws {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 1, 1],
        ]))

        #expect(gameEvents.count == 0)

        game.next()

        let firstBoardBlock = try #require(game.board.current)

        #expect(gameEvents.count == 2)
        #expect(gameEvents[0]?.newBlockAction != nil)
        #expect(gameEvents[0]?.newBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[0]?.newBlockAction?.boardBlock.x == 0)
        #expect(gameEvents[0]?.newBlockAction?.boardBlock.y == -3)
        #expect(gameEvents[1]?.moveBlockAction != nil)
        #expect(gameEvents[1]?.moveBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[1]?.moveBlockAction?.boardBlock.x == 0)
        #expect(gameEvents[1]?.moveBlockAction?.boardBlock.y == -2)
        #expect(gameEvents[1]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[1]?.moveBlockAction?.movedByGame == true)
        #expect(gameEvents[1]?.moveBlockAction?.expectCommitAndClearFullRows == false)

        game.next()

        #expect(gameEvents.count == 3)
        #expect(gameEvents[2]?.moveBlockAction != nil)
        #expect(gameEvents[2]?.moveBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[2]?.moveBlockAction?.boardBlock.x == 0)
        #expect(gameEvents[2]?.moveBlockAction?.boardBlock.y == -1)
        #expect(gameEvents[2]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[2]?.moveBlockAction?.movedByGame == true)
        #expect(gameEvents[2]?.moveBlockAction?.expectCommitAndClearFullRows == false)

        game.moveLeft()

        #expect(gameEvents.count == 4)
        #expect(gameEvents[3]?.moveBlockAction != nil)
        #expect(gameEvents[3]?.moveBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[3]?.moveBlockAction?.boardBlock.x == -1)
        #expect(gameEvents[3]?.moveBlockAction?.boardBlock.y == -1)
        #expect(gameEvents[3]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[3]?.moveBlockAction?.movedByGame == false)
        #expect(gameEvents[3]?.moveBlockAction?.expectCommitAndClearFullRows == false)

        game.moveLeft() // move left not possible

        #expect(gameEvents.count == 4)

        game.moveDown()

        #expect(gameEvents.count == 5)
        #expect(gameEvents[4]?.moveBlockAction != nil)
        #expect(gameEvents[4]?.moveBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[4]?.moveBlockAction?.boardBlock.x == -1)
        #expect(gameEvents[4]?.moveBlockAction?.boardBlock.y == 0)
        #expect(gameEvents[4]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[4]?.moveBlockAction?.movedByGame == false)
        #expect(gameEvents[4]?.moveBlockAction?.expectCommitAndClearFullRows == false)

        game.rotateClockwise()

        #expect(gameEvents.count == 6)
        #expect(gameEvents[5]?.moveBlockAction != nil)
        #expect(gameEvents[5]?.moveBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[5]?.moveBlockAction?.boardBlock.x == -1)
        #expect(gameEvents[5]?.moveBlockAction?.boardBlock.y == 0)
        #expect(gameEvents[5]?.moveBlockAction?.boardBlock.blockRotation == .clockwise90)
        #expect(gameEvents[5]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[5]?.moveBlockAction?.movedByGame == false)
        #expect(gameEvents[5]?.moveBlockAction?.expectCommitAndClearFullRows == false)

        game.moveDown()

        #expect(gameEvents.count == 9)
        #expect(gameEvents[6]?.moveBlockAction != nil)
        #expect(gameEvents[6]?.moveBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[6]?.moveBlockAction?.boardBlock.x == -1)
        #expect(gameEvents[6]?.moveBlockAction?.boardBlock.y == 1)
        #expect(gameEvents[6]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[6]?.moveBlockAction?.movedByGame == false)
        #expect(gameEvents[6]?.moveBlockAction?.expectCommitAndClearFullRows == true)
        #expect(gameEvents[7]?.commitBlockAction != nil)
        #expect(gameEvents[7]?.commitBlockAction?.boardBlock.id == firstBoardBlock.id)
        #expect(gameEvents[7]?.commitBlockAction?.boardBlock.x == -1)
        #expect(gameEvents[7]?.commitBlockAction?.boardBlock.y == 1)
        #expect(gameEvents[8]?.clearFullRowsAction != nil)
        #expect(gameEvents[8]?.clearFullRowsAction?.fullRows == [3])

        game.moveDown() // move down not possible

        #expect(gameEvents.count == 9)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()

        let secondBoardBlock = try #require(game.board.current)

        #expect(firstBoardBlock.id != secondBoardBlock.id)
        #expect(gameEvents.count == 11)
        #expect(gameEvents[9]?.newBlockAction != nil)
        #expect(gameEvents[9]?.newBlockAction?.boardBlock.id == secondBoardBlock.id)
        #expect(gameEvents[9]?.newBlockAction?.boardBlock.x == 0)
        #expect(gameEvents[9]?.newBlockAction?.boardBlock.y == -3)
        #expect(gameEvents[10]?.moveBlockAction != nil)
        #expect(gameEvents[10]?.moveBlockAction?.boardBlock.id == secondBoardBlock.id)
        #expect(gameEvents[10]?.moveBlockAction?.boardBlock.x == 0)
        #expect(gameEvents[10]?.moveBlockAction?.boardBlock.y == -2)
        #expect(gameEvents[10]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[10]?.moveBlockAction?.movedByGame == true)
        #expect(gameEvents[10]?.moveBlockAction?.expectCommitAndClearFullRows == false)

        game.moveRight()

        #expect(gameEvents.count == 12)
        #expect(gameEvents[11]?.moveBlockAction != nil)
        #expect(gameEvents[11]?.moveBlockAction?.boardBlock.id == secondBoardBlock.id)
        #expect(gameEvents[11]?.moveBlockAction?.boardBlock.x == 1)
        #expect(gameEvents[11]?.moveBlockAction?.boardBlock.y == -2)
        #expect(gameEvents[11]?.moveBlockAction?.movedToBottom == false)
        #expect(gameEvents[11]?.moveBlockAction?.movedByGame == false)
        #expect(gameEvents[11]?.moveBlockAction?.expectCommitAndClearFullRows == false)

        game.moveRight() // move right not possible

        #expect(gameEvents.count == 12)

        game.moveToBottom()

        #expect(gameEvents.count == 15)
        #expect(gameEvents[12]?.moveBlockAction != nil)
        #expect(gameEvents[12]?.moveBlockAction?.boardBlock.id == secondBoardBlock.id)
        #expect(gameEvents[12]?.moveBlockAction?.boardBlock.x == 1)
        #expect(gameEvents[12]?.moveBlockAction?.boardBlock.y == 1)
        #expect(gameEvents[12]?.moveBlockAction?.movedToBottom == true)
        #expect(gameEvents[12]?.moveBlockAction?.movedByGame == false)
        #expect(gameEvents[12]?.moveBlockAction?.expectCommitAndClearFullRows == true)
        #expect(gameEvents[13]?.commitBlockAction != nil)
        #expect(gameEvents[13]?.commitBlockAction?.boardBlock.id == secondBoardBlock.id)
        #expect(gameEvents[13]?.commitBlockAction?.boardBlock.x == 1)
        #expect(gameEvents[13]?.commitBlockAction?.boardBlock.y == 1)
        #expect(gameEvents[14]?.clearFullRowsAction != nil)
        #expect(gameEvents[14]?.clearFullRowsAction?.fullRows == [3])
    }

    // When only using the Game API, clear full rows happens always when the block moves down.
    // But when using the Board API directly, edge cases are possible,
    // where clear full rows need to happen without movement.
    @Test(arguments: [
        { @MainActor (game: Game) -> Void in game.next() },
        { @MainActor (game: Game) -> Void in game.moveToBottom() },
    ])
    mutating func testClearFullRowsEdgeCases(_ gameMethod: @MainActor (Game) -> Void) throws {
        game.board.data = Array(Bricks([
            [0, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 0, 0],
        ]))

        game.next()

        var boardBlock = try #require(game.board.current)
        boardBlock.x = 1
        boardBlock.y = 1
        try game.board.updateCurrentBoardBlock(boardBlock)

        gameMethod(game)

        #expect(game.board.current == nil)
        #expect(!game.isOver)
        #expect(Bricks(game.board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 1, 0, 0],
        ]))
    }

}
