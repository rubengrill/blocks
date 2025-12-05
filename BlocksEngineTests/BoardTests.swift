//
//  BoardTests.swift
//  BlocksEngineTests
//
//  Created by Ruben Grill on 01.03.23.
//

import XCTest

@testable import BlocksEngine

private let blockShape = BlockShape(blockForm: .O, data: [
    [0, 0, 0, 0],
    [0, 1, 1, 0],
    [0, 1, 1, 0],
    [0, 0, 0, 0],
])

@MainActor
final class BoardTests: XCTestCase {

    let board = Board(columns: 4, rows: 4)

    func testBlockInsideFits() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 0))

        XCTAssertFalse(board.isOver)
        XCTAssertFalse(board.canCommit)
        XCTAssertTrue(board.canMoveLeft)
        XCTAssertTrue(board.canMoveRight)
        XCTAssertTrue(board.canMoveHorizontally)
    }

    func testBlockOutsideDoesNotFit() {
        for (x, y) in [(-4, 0), (4, 0), (0, -4), (0, 4)] {
            XCTAssertThrowsError(try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: y))) { error in
                XCTAssertEqual(error as? BoardError, BoardError.OutOfBoard)
            }
        }
    }

    func testBlockBoundsOutsideDoesNotFit() {
        // On top is missing, because it is allowed to be outside (for entering the board)
        for (x, y) in [(-3, 0), (3, 0), (0, 3)] {
            XCTAssertThrowsError(try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: y))) { error in
                XCTAssertEqual(error as? BoardError, BoardError.OutOfBoard)
            }
        }
    }

    func testBlockBoundsHorizontallyPartlyOutsideDoesNotFit() {
        for x in [-2, 2] {
            XCTAssertThrowsError(try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: 0))) { error in
                XCTAssertEqual(error as? BoardError, BoardError.OutOfBoard)
            }
        }
    }

    func testBlockBoundsOnBottomPartlyOutsideDoesNotFit() {
        XCTAssertThrowsError(try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 2))) { error in
            XCTAssertEqual(error as? BoardError, BoardError.OutOfBoard)
        }
    }

    func testBlockBoundsOnTopPartlyOutsideFits() throws {
        for y in [-3, -2] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))

            XCTAssertFalse(board.isOver)
            XCTAssertFalse(board.canCommit)
            XCTAssertTrue(board.canMoveLeft)
            XCTAssertTrue(board.canMoveRight)
            XCTAssertTrue(board.canMoveHorizontally)
        }
    }

    func testBlockBoundsHorizontallyInsideFits() throws {
        for x in [-1, 1] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: 0))

            XCTAssertFalse(board.isOver)
            XCTAssertFalse(board.canCommit)
            XCTAssertEqual(board.canMoveLeft, x == -1 ? false : true)
            XCTAssertEqual(board.canMoveRight, x == -1 ? true : false)
            XCTAssertTrue(board.canMoveHorizontally)
        }
    }

    func testBlockBoundsVerticallyInsideFits() throws {
        for y in [-1, 1] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))

            XCTAssertFalse(board.isOver)
            XCTAssertEqual(board.canCommit, y == -1 ? false : true)
            XCTAssertTrue(board.canMoveLeft)
            XCTAssertTrue(board.canMoveRight)
            XCTAssertTrue(board.canMoveHorizontally)
        }
    }

    func testBlockBoundsAboveBottomCannotBeCommitted() throws {
        for y in -3...0 {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))
            XCTAssertFalse(board.canCommit)
        }
    }

    func testBlockBoundsAtBottomCanBeCommitted() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 1))
        XCTAssertTrue(board.canCommit)

        try board.commitCurrentBoardBlock()
        XCTAssertNil(board.current)
        XCTAssertFalse(board.isOver)
        XCTAssertFalse(board.canCommit)
        XCTAssertFalse(board.canMoveLeft)
        XCTAssertFalse(board.canMoveRight)
        XCTAssertFalse(board.canMoveHorizontally)
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(Bricks(board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    func testBlockBoundsAboveFilledSpaceCannotBeCommitted() throws {
        board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        for y in [-3, -2] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))
            XCTAssertFalse(board.canCommit)
        }
    }

    func testBlockBoundsAtFilledSpaceCanBeCommitted() throws {
        board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -1))
        XCTAssertTrue(board.canCommit)

        try board.commitCurrentBoardBlock()
        XCTAssertNil(board.current)
        XCTAssertFalse(board.isOver)
        XCTAssertFalse(board.canCommit)
        XCTAssertFalse(board.canMoveLeft)
        XCTAssertFalse(board.canMoveRight)
        XCTAssertFalse(board.canMoveHorizontally)
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(Bricks(board.data), Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    func testCommitNotPossibleWhenCurrentBoardBlockIsMissing() throws {
        XCTAssertThrowsError(try board.commitCurrentBoardBlock()) { error in
            XCTAssertEqual(error as? BoardError, BoardError.NoCurrentBoardBlock)
        }

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 1))
        try board.commitCurrentBoardBlock()

        XCTAssertThrowsError(try board.commitCurrentBoardBlock()) { error in
            XCTAssertEqual(error as? BoardError, BoardError.NoCurrentBoardBlock)
        }
    }

    func testCommitNotPossibleWhenBoardBlockCanStillMoveDown() throws {
        board.data = Array(Bricks([
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 0))

        XCTAssertFalse(board.canCommit)
        XCTAssertThrowsError(try board.commitCurrentBoardBlock()) { error in
            XCTAssertEqual(error as? BoardError, BoardError.CurrentBoardBlockCanStillMoveDown)
        }
    }

    func testClearFullRows() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: -1, y: 1))
        try board.commitCurrentBoardBlock()
        XCTAssertFalse(board.canClearFullRows)

        board.clearFullRows() // Should have no effect

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 1))
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(board.fullRows, [2, 3]) // fullRows gets set already in updateCurrentBoardBlock()

        try board.commitCurrentBoardBlock()
        XCTAssertTrue(board.canClearFullRows)
        XCTAssertEqual(board.fullRows, [2, 3])
        XCTAssertEqual(Bricks(board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 1, 1, 1],
            [1, 1, 1, 1],
        ]))

        board.clearFullRows()
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(board.fullRows, [])
        XCTAssertEqual(Bricks(board.data), Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ]))
    }

    func testClearFullRowsMustBeCalledAfterCommit() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: -1, y: 1))
        try board.commitCurrentBoardBlock()

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 1))
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(board.fullRows, [2, 3]) // fullRows gets set already in updateCurrentBoardBlock()

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 0))
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(board.fullRows, []) // fullRows can get reset again

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 1))
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(board.fullRows, [2, 3])

        try board.commitCurrentBoardBlock()
        XCTAssertTrue(board.canClearFullRows)
        XCTAssertEqual(board.fullRows, [2, 3])

        XCTAssertThrowsError(try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 0))) { error in
            XCTAssertEqual(error as? BoardError, BoardError.FullRowsNotCleared)
        }
    }

    func testGameIsOverAfterCommitWhenBlockBoundsEnteredOnlyPartially() throws {
        board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -2))
        XCTAssertFalse(board.isOver)
        XCTAssertTrue(board.canCommit)
        XCTAssertTrue(board.canMoveLeft)
        XCTAssertTrue(board.canMoveRight)
        XCTAssertTrue(board.canMoveHorizontally)
        XCTAssertFalse(board.canClearFullRows)

        try board.commitCurrentBoardBlock()
        XCTAssertTrue(board.isOver)
        XCTAssertFalse(board.canCommit)
        XCTAssertFalse(board.canMoveLeft)
        XCTAssertFalse(board.canMoveRight)
        XCTAssertFalse(board.canMoveHorizontally)
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(Bricks(board.data), Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    func testGameIsOverAfterCommitWhenBlockBoundsOutside() throws {
        board.data = Array(Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -3))
        XCTAssertFalse(board.isOver)
        XCTAssertTrue(board.canCommit)
        XCTAssertTrue(board.canMoveLeft)
        XCTAssertTrue(board.canMoveRight)
        XCTAssertTrue(board.canMoveHorizontally)
        XCTAssertFalse(board.canClearFullRows)

        try board.commitCurrentBoardBlock()
        XCTAssertTrue(board.isOver)
        XCTAssertFalse(board.canCommit)
        XCTAssertFalse(board.canMoveLeft)
        XCTAssertFalse(board.canMoveRight)
        XCTAssertFalse(board.canMoveHorizontally)
        XCTAssertFalse(board.canClearFullRows)
        XCTAssertEqual(Bricks(board.data), Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    func testNoFurtherActionsAllowedWhenGameIsOver() throws {
        board.data = Array(Bricks([
            [1, 0, 1, 1],
            [1, 0, 1, 1],
            [1, 0, 1, 1],
            [1, 1, 0, 1],
        ]))

        let blockShape = BlockShape(blockForm: .I, data: [
            [0, 1, 0, 0],
            [0, 1, 0, 0],
            [0, 1, 0, 0],
            [0, 1, 0, 0],
        ])

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -1))
        try board.commitCurrentBoardBlock()
        XCTAssertTrue(board.isOver)
        XCTAssertFalse(board.canCommit)
        XCTAssertFalse(board.canMoveLeft)
        XCTAssertFalse(board.canMoveRight)
        XCTAssertFalse(board.canMoveHorizontally)
        XCTAssertFalse(board.canClearFullRows)

        board.clearFullRows() // Should have no effect

        XCTAssertEqual(Bricks(board.data), Bricks([
            [1, 1, 1, 1],
            [1, 1, 1, 1],
            [1, 1, 1, 1],
            [1, 1, 0, 1],
        ]))

        XCTAssertThrowsError(try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -3))) { error in
            XCTAssertEqual(error as? BoardError, BoardError.GameOver)
        }

        XCTAssertThrowsError(try board.commitCurrentBoardBlock()) { error in
            XCTAssertEqual(error as? BoardError, BoardError.GameOver)
        }
    }

}
