//
//  Bricks.swift
//  BlocksEngineTests
//
//  Created by Ruben Grill on 10.04.23.
//

import BlocksEngine

struct Bricks: Sequence, Equatable {

    var bricks: [[Brick?]]

    init(_ bricks: [[Brick?]]) {
        self.bricks = bricks
    }

    init(_ numbers: [[Int]]) {
        bricks = numbers.map { columns in columns.map { $0 > 0 ? Brick(blockForm: .O) : nil } }
    }

    func makeIterator() -> some IteratorProtocol<[Brick?]> {
        bricks.makeIterator()
    }

    func toNumbers() -> [[Int]] {
        bricks.map { columns in columns.map { $0 == nil ? 0 : 1 }}
    }

    static func == (lhs: Bricks, rhs: Bricks) -> Bool {
        lhs.toNumbers() == rhs.toNumbers()
    }

}

extension Bricks: CustomDebugStringConvertible {

    var debugDescription: String {
        let result = bricks.map { $0.map { $0 == nil ? "0" : "1" }.joined(separator: " ") }.joined(separator: "\n")
        return "\n\(result)\n"
    }

}
