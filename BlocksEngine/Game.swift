//
//  Game.swift
//  BlocksEngine
//
//  Created by Ruben Grill on 05.03.23.
//

struct RandomBlockIterator: IteratorProtocol {

    private let blockRotations: [BlockRotation] = [.clockwise0, .clockwise90, .clockwise180, .clockwise270]

    func next() -> BoardBlock? {
        let blockShapeIndex = Int.random(in: 0 ..< BlockShape.shapes.count)
        let blockShape = BlockShape.shapes[blockShapeIndex]
        let blockRotationIndex = Int.random(in: 0 ..< blockRotations.count)
        let blockRotation = blockRotations[blockRotationIndex]
        return BoardBlock(blockShape: blockShape, blockRotation: blockRotation, x: 0, y: 0)
    }
}

public struct NewBlockAction {
    public var boardBlock: BoardBlock
    public var projectedBoardBlock: BoardBlock
}

public struct MoveBlockAction {
    public var boardBlock: BoardBlock
    public var projectedBoardBlock: BoardBlock
    public var movedToBottom: Bool
    public var movedByGame: Bool
    public var expectCommitAndClearFullRows: Bool
}

public struct CommitBlockAction {
    public var boardBlock: BoardBlock
}

public struct ClearFullRowsAction {
    public var fullRows: Set<Int>
}

public struct GameOverAction {
}

@MainActor
public protocol GameDelegate: AnyObject {
    func game(_ game: Game, newBlock action: NewBlockAction)
    func game(_ game: Game, moveBlock action: MoveBlockAction)
    func game(_ game: Game, commitBlock action: CommitBlockAction)
    func game(_ game: Game, clearFullRows action: ClearFullRowsAction)
    func game(_ game: Game, gameOver action: GameOverAction)
}

@MainActor
public final class Game {

    public let board: Board
    public var isOver: Bool { board.isOver }
    public weak var delegate: GameDelegate?

    var blocks: any IteratorProtocol<BoardBlock> = RandomBlockIterator()

    public init(columns: Int, rows: Int) {
        board = Board(columns: columns, rows: rows)
    }

    public func moveLeft() {
        guard !board.isOver, let currentBoardBlock = board.current, board.canMoveLeft else { return }
        let updatedBoardBlock = currentBoardBlock.moveX(offset: -1)
        try! board.updateCurrentBoardBlock(updatedBoardBlock)
        let moveBlockAction = MoveBlockAction(
            boardBlock: updatedBoardBlock,
            projectedBoardBlock: board.projected!,
            movedToBottom: false,
            movedByGame: false,
            expectCommitAndClearFullRows: false
        )
        delegate?.game(self, moveBlock: moveBlockAction)
    }

    public func moveRight() {
        guard !board.isOver, let currentBoardBlock = board.current, board.canMoveRight else { return }
        let updatedBoardBlock = currentBoardBlock.moveX(offset: 1)
        try! board.updateCurrentBoardBlock(updatedBoardBlock)
        let moveBlockAction = MoveBlockAction(
            boardBlock: updatedBoardBlock,
            projectedBoardBlock: board.projected!,
            movedToBottom: false,
            movedByGame: false,
            expectCommitAndClearFullRows: false
        )
        delegate?.game(self, moveBlock: moveBlockAction)
    }

    public func moveDown() {
        guard !board.isOver, let currentBoardBlock = board.current, !board.canCommit else { return }
        let updatedBoardBlock = currentBoardBlock.moveY(offset: 1)
        try! board.updateCurrentBoardBlock(updatedBoardBlock)
        movedDown(movedToBottom: false, movedByGame: false)
    }

    public func moveToBottom() {
        guard !board.isOver, let projectedBoardBlock = board.projected else { return }

        if !board.canCommit {
            try! board.updateCurrentBoardBlock(projectedBoardBlock)
            assert(board.canCommit)
            movedDown(movedToBottom: true, movedByGame: false)
        }

        // movedDown() only commits when moving down results in full rows to clear.
        // If we can commit here, the block only moved to the bottom (no full rows),
        // or the block was already at the bottom (also no full rows if only Game API is used).
        if board.canCommit {
            commit()

            if board.isOver {
                return gameOver()
            }

            // When only using the Game API, canClearFullRows should never be true here,
            // since Game clears full rows always when moving down already.
            // However, it is possible that clients use the Board API directly, so we can't assert() here.
            if board.canClearFullRows {
                clearFullRows()
            }
        }
    }

    public func rotateClockwise() {
        guard !board.isOver, let currentBoardBlock = board.current else { return }

        let rotatedBoardBlock = currentBoardBlock.rotateClockwise()

        for xOffset in [0, -1, 1] {
            do {
                let updatedBoardBlock = rotatedBoardBlock.moveX(offset: xOffset)
                try board.updateCurrentBoardBlock(updatedBoardBlock)
                let moveBlockAction = MoveBlockAction(
                    boardBlock: updatedBoardBlock,
                    projectedBoardBlock: board.projected!,
                    movedToBottom: false,
                    movedByGame: false,
                    expectCommitAndClearFullRows: false
                )
                delegate?.game(self, moveBlock: moveBlockAction)
                break
            } catch {
                assert(error == .Overlaps || error == .OutOfBoard)
                continue
            }
        }
    }

    public func next() {
        guard !board.isOver else { return }

        if board.canCommit {
            commit()

            if board.isOver {
                return gameOver()
            }

            // When only using the Game API, canClearFullRows should never be true here,
            // since Game clears full rows always when moving down already.
            // However, it is possible that clients use the Board API directly, so we can't assert() here.
            // If it happens, we return to consistently clear full rows as the last action within next().
            if board.canClearFullRows {
                return clearFullRows()
            }
        }

        if board.current == nil {
            let newBoardBlock = createNewBlock()
            try! board.updateCurrentBoardBlock(newBoardBlock)
            delegate?.game(self, newBlock: NewBlockAction(boardBlock: newBoardBlock, projectedBoardBlock: board.projected!))

            if board.canCommit {
                commit()
                assert(board.isOver)
                return gameOver()
            }
        }

        assert(board.current != nil)
        assert(!board.canCommit)

        let updatedBoardBlock = board.current!.moveY(offset: 1)
        try! board.updateCurrentBoardBlock(updatedBoardBlock)
        movedDown(movedToBottom: false, movedByGame: true)
    }

    private func movedDown(movedToBottom: Bool, movedByGame: Bool) {
        let boardBlock = board.current!
        let expectCommitAndClearFullRows = !board.fullRows.isEmpty
        let moveBlockAction = MoveBlockAction(
            boardBlock: boardBlock,
            projectedBoardBlock: board.projected!,
            movedToBottom: movedToBottom,
            movedByGame: movedByGame,
            expectCommitAndClearFullRows: expectCommitAndClearFullRows
        )
        delegate?.game(self, moveBlock: moveBlockAction)

        if expectCommitAndClearFullRows {
            assert(board.canCommit)
            assert(!board.fullRows.isEmpty)
            assert(!board.canMoveHorizontally)

            commit()

            if board.isOver {
                return gameOver()
            }

            assert(board.canClearFullRows)

            clearFullRows()
        }
    }

    private func createNewBlock() -> BoardBlock {
        var boardBlock = blocks.next()!
        boardBlock.x = (board.columns - boardBlock.block.size) / 2
        boardBlock.y = -boardBlock.block.rowBounds.last! - 1
        return boardBlock
    }

    private func commit() {
        assert(board.canCommit)
        let boardBlock = board.current!
        try! board.commitCurrentBoardBlock()
        delegate?.game(self, commitBlock: CommitBlockAction(boardBlock: boardBlock))
    }

    private func clearFullRows() {
        assert(board.canClearFullRows)
        let fullRows = board.fullRows
        board.clearFullRows()
        delegate?.game(self, clearFullRows: ClearFullRowsAction(fullRows: fullRows))
    }

    private func gameOver() {
        assert(board.isOver)
        delegate?.game(self, gameOver: GameOverAction())
    }

}
