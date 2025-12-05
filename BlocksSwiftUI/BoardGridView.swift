//
//  BoardGridView.swift
//  BlocksSwiftUI
//
//  Created by Ruben Grill on 11.04.23.
//

import SwiftUI

struct BoardGridView: InsettableShape {

    var columns: Int
    var rows: Int
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for columnIndex in 0...columns {
            let x = (rect.width - inset * 2) / CGFloat(columns) * CGFloat(columnIndex) + inset
            path.move(to: CGPoint(x: x, y: inset))
            path.addLine(to: CGPoint(x: x, y: rect.height - inset))
        }

        for rowIndex in 0...rows {
            let y = (rect.height - inset * 2) / CGFloat(rows) * CGFloat(rowIndex) + inset
            path.move(to: CGPoint(x: inset, y: y))
            path.addLine(to: CGPoint(x: rect.width - inset, y: y))
        }

        return path
    }

    func inset(by amount: CGFloat) -> BoardGridView {
        BoardGridView(columns: columns, rows: rows, inset: inset + amount)
    }

}

#Preview("Only strokeBorder") {
    BoardGridView(columns: 10, rows: 20)
        .strokeBorder(.tint, lineWidth: 2)
        .background(Color("background"))
        .ignoresSafeArea()
}

#Preview("Inset and strokeBorder") {
    BoardGridView(columns: 10, rows: 20, inset: 10)
        .strokeBorder(.tint, lineWidth: 2)
        .background(Color("background"))
        .ignoresSafeArea()
}
