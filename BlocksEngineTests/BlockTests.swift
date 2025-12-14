//
//  BlocksTests.swift
//  BlocksEngineTests
//
//  Created by Ruben Grill on 26.02.23.
//

import Testing

@testable import BlocksEngine

@Suite
struct BlockTests {

    @Test
    func testBlockShape() {
        let blockShape = BlockShape(blockForm: .L, data: [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ])

        #expect(blockShape.blockClockwise0.data == [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 1],
        ])
        #expect(blockShape.blockClockwise0.rowBounds == 0...2)
        #expect(blockShape.blockClockwise0.columnBounds == 1...2)

        #expect(blockShape.blockClockwise90.data == [
            [0, 0, 0],
            [1, 1, 1],
            [1, 0, 0],
        ])
        #expect(blockShape.blockClockwise90.rowBounds == 1...2)
        #expect(blockShape.blockClockwise90.columnBounds == 0...2)

        #expect(blockShape.blockClockwise180.data == [
            [1, 1, 0],
            [0, 1, 0],
            [0, 1, 0],
        ])
        #expect(blockShape.blockClockwise180.rowBounds == 0...2)
        #expect(blockShape.blockClockwise180.columnBounds == 0...1)

        #expect(blockShape.blockClockwise270.data == [
            [0, 0, 1],
            [1, 1, 1],
            [0, 0, 0],
        ])
        #expect(blockShape.blockClockwise270.rowBounds == 0...1)
        #expect(blockShape.blockClockwise270.columnBounds == 0...2)
    }

}
