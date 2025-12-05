//
//  BoardGridView.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 11.03.23.
//

import UIKit

class BoardGridView: UIView {

    var columns: Int = 0 { didSet { setNeedsDisplay() } }
    var rows: Int = 0 { didSet { setNeedsDisplay() } }
    var color: UIColor = .tintColor { didSet { setNeedsDisplay() } }
    var lineWidth: CGFloat = 2 { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)

        let inset = lineWidth / 2

        for columnIndex in 0...columns {
            let x = (bounds.width - inset * 2) / CGFloat(columns) * CGFloat(columnIndex) + inset
            context.move(to: CGPoint(x: x, y: inset))
            context.addLine(to: CGPoint(x: x, y: bounds.height - inset))
            context.strokePath()
        }

        for rowIndex in 0...rows {
            let y = (bounds.height - inset * 2) / CGFloat(rows) * CGFloat(rowIndex) + inset
            context.move(to: CGPoint(x: inset, y: y))
            context.addLine(to: CGPoint(x: bounds.width - inset, y: y))
            context.strokePath()
        }
    }

}

#Preview {
    let view = BoardGridView()
    view.columns = 10
    view.rows = 20
    view.backgroundColor = UIColor(named: "background")
    return view
}
