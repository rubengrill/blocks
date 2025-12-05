//
//  Block.swift
//  BlocksEngine
//
//  Created by Ruben Grill on 26.02.23.
//

public enum BlockForm: String, Sendable {
    case I
    case J
    case L
    case O
    case S
    case T
    case Z
}

// Immutable reference type, to avoid copying data unnecessarily where blocks are stored.
public final class Block: Sendable {

    public let blockForm: BlockForm

    /// Mapping of row > column > 0/1, where 0 is background and 1 is content. Always a square. Never just background.
    public let data: [[Int]]

    /// Range from the first row index to the last row index, where at least one column has content.
    public let rowBounds: ClosedRange<Int>

    /// Range from the first column index to the last column index, where at least one row has content.
    public let columnBounds: ClosedRange<Int>

    /// Size of the square. In other words, count of each row and each column.
    public var size: Int { data.count }

    fileprivate init(blockForm: BlockForm, data: [[Int]]) {
        Block.validateData(data)

        let size = data.count
        let indexRange = 0 ..< size
        var nonEmptyRowIndices: Set<Int> = []
        var nonEmptyColumnIndices: Set<Int> = []

        for rowIndex in indexRange {
            if indexRange.contains(where: { data[rowIndex][$0] > 0 }) {
                nonEmptyRowIndices.insert(rowIndex)
            }
        }

        for columnIndex in indexRange {
            if indexRange.contains(where: { data[$0][columnIndex] > 0 }) {
                nonEmptyColumnIndices.insert(columnIndex)
            }
        }

        assert(nonEmptyRowIndices.count > 0)
        assert(nonEmptyColumnIndices.count > 0)

        self.blockForm = blockForm
        self.data = data
        self.rowBounds = nonEmptyRowIndices.min()! ... nonEmptyRowIndices.max()!
        self.columnBounds = nonEmptyColumnIndices.min()! ... nonEmptyColumnIndices.max()!
    }

    fileprivate static func validateData(_ data: [[Int]]) {
        let size = data.count

        assert(size > 0)

        for row in data {
            assert(row.count == size)

            for value in row {
                assert(value == 0 || value == 1)
            }
        }
    }

}

public enum BlockRotation {

    case clockwise0
    case clockwise90
    case clockwise180
    case clockwise270

    public func rotateClockwise() -> BlockRotation {
        switch self {
        case .clockwise0: .clockwise90
        case .clockwise90: .clockwise180
        case .clockwise180: .clockwise270
        case .clockwise270: .clockwise0
        }
    }

}

public struct BlockShape: Sendable {

    public let blockForm: BlockForm
    public let blockClockwise0: Block
    public let blockClockwise90: Block
    public let blockClockwise180: Block
    public let blockClockwise270: Block

    init(blockForm: BlockForm, data: [[Int]]) {
        Block.validateData(data)

        let dataClockwise90 = BlockShape.rotateClockwiseBy90(data)
        let dataClockwise180 = BlockShape.rotateClockwiseBy90(dataClockwise90)
        let dataClockwise270 = BlockShape.rotateClockwiseBy90(dataClockwise180)

        self.blockForm = blockForm
        self.blockClockwise0 = Block(blockForm: blockForm, data: data)
        self.blockClockwise90 = Block(blockForm: blockForm, data: dataClockwise90)
        self.blockClockwise180 = Block(blockForm: blockForm, data: dataClockwise180)
        self.blockClockwise270 = Block(blockForm: blockForm, data: dataClockwise270)
    }

    public func getBlock(for rotation: BlockRotation) -> Block {
        switch rotation {
        case .clockwise0: blockClockwise0
        case .clockwise90: blockClockwise90
        case .clockwise180: blockClockwise180
        case .clockwise270: blockClockwise270
        }
    }

    private static func rotateClockwiseBy90(_ data: [[Int]]) -> [[Int]] {
        let size = data.count
        var result = data

        for (rowIndex, row) in data.enumerated() {
            let targetColumnIndex = size - rowIndex - 1

            for (columnIndex, value) in row.enumerated() {
                let targetRowIndex = columnIndex

                result[targetRowIndex][targetColumnIndex] = value
            }
        }

        return result
    }

}

extension BlockShape {

    public static let shapes = [
        BlockShape(blockForm: .L, data: [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ]),
        BlockShape(blockForm: .J, data: [
            [0, 1, 0],
            [0, 1, 0],
            [1, 1, 0],
        ]),
        BlockShape(blockForm: .O, data: [
            [1, 1],
            [1, 1],
        ]),
        BlockShape(blockForm: .I, data: [
            [0, 1, 0, 0],
            [0, 1, 0, 0],
            [0, 1, 0, 0],
            [0, 1, 0, 0],
        ]),
        BlockShape(blockForm: .T, data: [
            [0, 1, 0],
            [0, 1, 1],
            [0, 1, 0],
        ]),
        BlockShape(blockForm: .Z, data: [
            [0, 0, 1],
            [0, 1, 1],
            [0, 1, 0],
        ]),
        BlockShape(blockForm: .S, data: [
            [0, 1, 0],
            [0, 1, 1],
            [0, 0, 1],
        ]),
    ]

}
