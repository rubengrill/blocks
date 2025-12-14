//
//  BoardTests.swift
//  BlocksEngineTests
//
//  Created by Ruben Grill on 01.03.23.
//

import Testing

@testable import BlocksEngine

private let blockShape = BlockShape(blockForm: .O, data: [
    [0, 0, 0, 0],
    [0, 1, 1, 0],
    [0, 1, 1, 0],
    [0, 0, 0, 0],
])

@MainActor
@Suite
struct BoardTests {

    let board = Board(columns: 4, rows: 4)

    @Test
    func testBlockInsideFits() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 0))

        #expect(!board.isOver)
        #expect(!board.canCommit)
        #expect(board.canMoveLeft)
        #expect(board.canMoveRight)
        #expect(board.canMoveHorizontally)
    }

    @Test
    func testBlockOutsideDoesNotFit() {
        for (x, y) in [(-4, 0), (4, 0), (0, -4), (0, 4)] {
            #expect(throws: BoardError.OutOfBoard) {
                try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: y))
            }
        }
    }

    @Test
    func testBlockBoundsOutsideDoesNotFit() {
        // On top is missing, because it is allowed to be outside (for entering the board)
        for (x, y) in [(-3, 0), (3, 0), (0, 3)] {
            #expect(throws: BoardError.OutOfBoard) {
                try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: y))
            }
        }
    }

    @Test
    func testBlockBoundsHorizontallyPartlyOutsideDoesNotFit() {
        for x in [-2, 2] {
            #expect(throws: BoardError.OutOfBoard) {
                try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: 0))
            }
        }
    }

    @Test
    func testBlockBoundsOnBottomPartlyOutsideDoesNotFit() {
        #expect(throws: BoardError.OutOfBoard) {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 2))
        }
    }

    @Test
    func testBlockBoundsOnTopPartlyOutsideFits() throws {
        for y in [-3, -2] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))

            #expect(!board.isOver)
            #expect(!board.canCommit)
            #expect(board.canMoveLeft)
            #expect(board.canMoveRight)
            #expect(board.canMoveHorizontally)
        }
    }

    @Test
    func testBlockBoundsHorizontallyInsideFits() throws {
        for x in [-1, 1] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: x, y: 0))

            #expect(!board.isOver)
            #expect(!board.canCommit)
            #expect(board.canMoveLeft == (x == -1 ? false : true))
            #expect(board.canMoveRight == (x == -1 ? true : false))
            #expect(board.canMoveHorizontally)
        }
    }

    @Test
    func testBlockBoundsVerticallyInsideFits() throws {
        for y in [-1, 1] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))

            #expect(!board.isOver)
            #expect(board.canCommit == (y == -1 ? false : true))
            #expect(board.canMoveLeft)
            #expect(board.canMoveRight)
            #expect(board.canMoveHorizontally)
        }
    }

    @Test
    func testBlockBoundsAboveBottomCannotBeCommitted() throws {
        for y in -3...0 {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))
            #expect(!board.canCommit)
        }
    }

    @Test
    func testBlockBoundsAtBottomCanBeCommitted() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 1))
        #expect(board.canCommit)

        try board.commitCurrentBoardBlock()
        #expect(board.current == nil)
        #expect(!board.isOver)
        #expect(!board.canCommit)
        #expect(!board.canMoveLeft)
        #expect(!board.canMoveRight)
        #expect(!board.canMoveHorizontally)
        #expect(!board.canClearFullRows)
        #expect(Bricks(board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    @Test
    func testBlockBoundsAboveFilledSpaceCannotBeCommitted() throws {
        board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        for y in [-3, -2] {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: y))
            #expect(!board.canCommit)
        }
    }

    @Test
    func testBlockBoundsAtFilledSpaceCanBeCommitted() throws {
        board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -1))
        #expect(board.canCommit)

        try board.commitCurrentBoardBlock()
        #expect(board.current == nil)
        #expect(!board.isOver)
        #expect(!board.canCommit)
        #expect(!board.canMoveLeft)
        #expect(!board.canMoveRight)
        #expect(!board.canMoveHorizontally)
        #expect(!board.canClearFullRows)
        #expect(Bricks(board.data) == Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    @Test
    func testCommitNotPossibleWhenCurrentBoardBlockIsMissing() throws {
        #expect(throws: BoardError.NoCurrentBoardBlock) {
            try board.commitCurrentBoardBlock()
        }

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 1))
        try board.commitCurrentBoardBlock()

        #expect(throws: BoardError.NoCurrentBoardBlock) {
            try board.commitCurrentBoardBlock()
        }
    }

    @Test
    func testCommitNotPossibleWhenBoardBlockCanStillMoveDown() throws {
        board.data = Array(Bricks([
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: 0))

        #expect(!board.canCommit)
        #expect(throws: BoardError.CurrentBoardBlockCanStillMoveDown) {
            try board.commitCurrentBoardBlock()
        }
    }

    @Test
    func testClearFullRows() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: -1, y: 1))
        try board.commitCurrentBoardBlock()
        #expect(!board.canClearFullRows)

        board.clearFullRows() // Should have no effect

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 1))
        #expect(!board.canClearFullRows)
        #expect(board.fullRows == [2, 3]) // fullRows gets set already in updateCurrentBoardBlock()

        try board.commitCurrentBoardBlock()
        #expect(board.canClearFullRows)
        #expect(board.fullRows == [2, 3])
        #expect(Bricks(board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1, 1, 1, 1],
            [1, 1, 1, 1],
        ]))

        board.clearFullRows()
        #expect(!board.canClearFullRows)
        #expect(board.fullRows.isEmpty)
        #expect(Bricks(board.data) == Bricks([
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ]))
    }

    @Test
    func testClearFullRowsMustBeCalledAfterCommit() throws {
        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: -1, y: 1))
        try board.commitCurrentBoardBlock()

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 1))
        #expect(!board.canClearFullRows)
        #expect(board.fullRows == [2, 3]) // fullRows gets set already in updateCurrentBoardBlock()

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 0))
        #expect(!board.canClearFullRows)
        #expect(board.fullRows.isEmpty) // fullRows can get reset again

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 1))
        #expect(!board.canClearFullRows)
        #expect(board.fullRows == [2, 3])

        try board.commitCurrentBoardBlock()
        #expect(board.canClearFullRows)
        #expect(board.fullRows == [2, 3])

        #expect(throws: BoardError.FullRowsNotCleared) {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 1, y: 0))
        }
    }

    @Test
    func testGameIsOverAfterCommitWhenBlockBoundsEnteredOnlyPartially() throws {
        board.data = Array(Bricks([
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -2))
        #expect(!board.isOver)
        #expect(board.canCommit)
        #expect(board.canMoveLeft)
        #expect(board.canMoveRight)
        #expect(board.canMoveHorizontally)
        #expect(!board.canClearFullRows)

        try board.commitCurrentBoardBlock()
        #expect(board.isOver)
        #expect(!board.canCommit)
        #expect(!board.canMoveLeft)
        #expect(!board.canMoveRight)
        #expect(!board.canMoveHorizontally)
        #expect(!board.canClearFullRows)
        #expect(Bricks(board.data) == Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    @Test
    func testGameIsOverAfterCommitWhenBlockBoundsOutside() throws {
        board.data = Array(Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))

        try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -3))
        #expect(!board.isOver)
        #expect(board.canCommit)
        #expect(board.canMoveLeft)
        #expect(board.canMoveRight)
        #expect(board.canMoveHorizontally)
        #expect(!board.canClearFullRows)

        try board.commitCurrentBoardBlock()
        #expect(board.isOver)
        #expect(!board.canCommit)
        #expect(!board.canMoveLeft)
        #expect(!board.canMoveRight)
        #expect(!board.canMoveHorizontally)
        #expect(!board.canClearFullRows)
        #expect(Bricks(board.data) == Bricks([
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ]))
    }

    @Test
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
        #expect(board.isOver)
        #expect(!board.canCommit)
        #expect(!board.canMoveLeft)
        #expect(!board.canMoveRight)
        #expect(!board.canMoveHorizontally)
        #expect(!board.canClearFullRows)

        board.clearFullRows() // Should have no effect

        #expect(Bricks(board.data) == Bricks([
            [1, 1, 1, 1],
            [1, 1, 1, 1],
            [1, 1, 1, 1],
            [1, 1, 0, 1],
        ]))

        #expect(throws: BoardError.GameOver) {
            try board.updateCurrentBoardBlock(BoardBlock(blockShape: blockShape, blockRotation: .clockwise0, x: 0, y: -3))
        }

        #expect(throws: BoardError.GameOver) {
            try board.commitCurrentBoardBlock()
        }
    }

}
