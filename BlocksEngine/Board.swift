//
//  Board.swift
//  BlocksEngine
//
//  Created by Ruben Grill on 27.02.23.
//

import Foundation

public enum BoardError: Error {
    case FullRowsNotCleared
    case OutOfBoard
    case Overlaps
    case NoCurrentBoardBlock
    case CurrentBoardBlockCanStillMoveDown
    case GameOver
}

public struct BoardBlock: Identifiable {

    public var id = UUID()
    public var blockShape: BlockShape
    public var blockRotation: BlockRotation
    public var x: Int
    public var y: Int

    public var block: Block { blockShape.getBlock(for: blockRotation) }

    public init(blockShape: BlockShape, blockRotation: BlockRotation, x: Int, y: Int) {
        self.blockShape = blockShape
        self.blockRotation = blockRotation
        self.x = x
        self.y = y
    }

    public func moveX(offset: Int) -> BoardBlock {
        var copy = self
        copy.x += offset
        return copy
    }

    public func moveY(offset: Int) -> BoardBlock {
        var copy = self
        copy.y += offset
        return copy
    }

    public func rotateClockwise() -> BoardBlock {
        var copy = self
        copy.blockRotation = blockRotation.rotateClockwise()
        return copy
    }

}

@MainActor
public final class Board {

    public let columns: Int
    public let rows: Int

    public private(set) var isOver = false
    public private(set) var canCommit = false
    public private(set) var canMoveLeft = false
    public private(set) var canMoveRight = false

    /// Contains row indexes of full rows which can be cleared.
    /// fullRows is already set when calling updateCurrentBoardBlock().
    /// This helps to know already before committing, whether full rows can be cleared after a commit.
    /// Note that full rows can only be cleared after a commit (canClearFullRows returns true only after a commit).
    public private(set) var fullRows: Set<Int> = []
    public internal(set) var data: [[Brick?]]

    public var canMoveHorizontally: Bool { canMoveLeft || canMoveRight }
    public var canClearFullRows: Bool { !isOver && !canCommit && !fullRows.isEmpty }
    public var current: BoardBlock? { currentBoardBlock }
    public var projected: BoardBlock? { currentBoardBlockProjected }

    private var currentBoardBlock: BoardBlock?
    private var currentBoardBlockFillPositions: [(x: Int, y: Int)] = []
    private var currentBoardBlockProjected: BoardBlock?

    public init(columns: Int, rows: Int) {
        assert(columns > 0)
        assert(rows > 0)

        let row = Array<Brick?>(repeating: nil, count: columns)
        let data = Array(repeating: row, count: rows)

        self.columns = columns
        self.rows = rows
        self.data = data
    }

    public func updateCurrentBoardBlock(_ boardBlock: BoardBlock) throws(BoardError) {
        guard !isOver else { throw BoardError.GameOver }
        guard fullRows.isEmpty || currentBoardBlock != nil else { throw BoardError.FullRowsNotCleared }

        let boardBlockFillPositions = try checkBoardBlockFits(boardBlock)
        let boardBlockProjected = projectBoardBlock(boardBlock)

        currentBoardBlock = boardBlock
        currentBoardBlockFillPositions = boardBlockFillPositions
        currentBoardBlockProjected = boardBlockProjected
        canCommit = boardBlock.y == boardBlockProjected.y
        canMoveLeft = (try? checkBoardBlockFits(boardBlock.moveX(offset: -1))) != nil
        canMoveRight = (try? checkBoardBlockFits(boardBlock.moveX(offset: 1))) != nil
        fullRows = []

        if canCommit {
            let fillPositionsByRowIndex = Dictionary(grouping: currentBoardBlockFillPositions, by: { $0.y })
            let columnIndexesByRowIndex = fillPositionsByRowIndex.mapValues { Set($0.map { $0.x }) }

            for (rowIndex, columnIndexes) in columnIndexesByRowIndex {
                if data[rowIndex].enumerated().allSatisfy({ $0.element != nil || columnIndexes.contains($0.offset) }) {
                    fullRows.insert(rowIndex)
                }
            }
        }
    }

    public func commitCurrentBoardBlock() throws(BoardError) {
        guard !isOver else { throw BoardError.GameOver }
        guard let currentBoardBlock else { throw BoardError.NoCurrentBoardBlock }
        guard canCommit else { throw BoardError.CurrentBoardBlockCanStillMoveDown }

        for (x, y) in currentBoardBlockFillPositions {
            data[y][x] = Brick(blockForm: currentBoardBlock.block.blockForm)
        }

        if currentBoardBlock.y < -currentBoardBlock.block.rowBounds.first! {
            isOver = true
        }

        self.currentBoardBlock = nil
        self.currentBoardBlockFillPositions = []
        self.currentBoardBlockProjected = nil
        self.canCommit = false
        self.canMoveLeft = false
        self.canMoveRight = false
    }

    public func clearFullRows() {
        guard canClearFullRows else { return }

        for y in fullRows.sorted() {
            data.remove(at: y)
            data.insert(Array(repeating: nil, count: columns), at: 0)
        }

        fullRows = []
    }

    private func checkBoardBlockFits(_ boardBlock: BoardBlock) throws(BoardError) -> [(x: Int, y: Int)] {
        let block = boardBlock.block
        let blockX = boardBlock.x + block.columnBounds.first!
        let blockY = boardBlock.y + block.rowBounds.first!
        let blockColumns = block.columnBounds.count
        let blockRows = block.rowBounds.count
        let minX = 0
        let minY = -blockRows // Allow entering from top

        if !(minX ..< columns).contains(blockX ..< blockX + blockColumns) {
            throw BoardError.OutOfBoard
        }

        if !(minY ..< rows).contains(blockY ..< blockY + blockRows) {
            throw BoardError.OutOfBoard
        }

        let skipRows = max(-blockY, 0)
        assert(skipRows <= blockRows)

        var fillPositions: [(x: Int, y: Int)] = []

        for rowIndex in block.rowBounds.suffix(blockRows - skipRows) {
            for columnIndex in block.columnBounds {
                if block.data[rowIndex][columnIndex] > 0 {
                    fillPositions.append((
                        x: columnIndex + boardBlock.x,
                        y: rowIndex + boardBlock.y
                    ))
                }
            }
        }

        for (x, y) in fillPositions where data[y][x] != nil {
            throw BoardError.Overlaps
        }

        return fillPositions
    }

    private func projectBoardBlock(_ boardBlock: BoardBlock) -> BoardBlock {
        var boardBlockProjected = boardBlock

        while true {
            boardBlockProjected.y += 1

            do {
                _ = try checkBoardBlockFits(boardBlockProjected)
            } catch {
                boardBlockProjected.y -= 1
                break
            }
        }

        return boardBlockProjected
    }

}
