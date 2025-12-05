//
//  BoardBlockView.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 11.03.23.
//

import BlocksEngine
import SwiftUI
import UIKit

class BoardBlockView: UIView {

    var columns: Int = 0 { didSet { setNeedsLayout() } }
    var rows: Int = 0 { didSet { setNeedsLayout() } }
    var boardBlock: BoardBlock? { didSet { updateBoardBlock(oldValue: oldValue) } }
    var isProjected = false { didSet { updateIsProjected() } }

    private let blockView = BlockView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Translate frame set in layoutSubviews() into constraints automatically
        blockView.translatesAutoresizingMaskIntoConstraints = true
        blockView.isHidden = true
        addSubview(blockView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let boardBlock else { return }
        guard columns > 0, rows > 0 else { return }

        let block = boardBlock.block
        let brickWidth = bounds.width / CGFloat(columns)
        let brickHeight = bounds.height / CGFloat(rows)
        let x = brickWidth * CGFloat(boardBlock.x)
        let y = brickHeight * CGFloat(boardBlock.y)
        let width = brickWidth * CGFloat(block.size)
        let height = brickHeight * CGFloat(block.size)

        blockView.frame = CGRect(x: x, y: y, width: width, height: height)
    }

    private func updateBoardBlock(oldValue: BoardBlock?) {
        guard let boardBlock else {
            blockView.block = nil
            blockView.isHidden = true
            return
        }
        let shouldAnimate = boardBlock.id == oldValue?.id && boardBlock.y != oldValue?.y
        UIView.animate(withDuration: shouldAnimate ? 0.15 : 0, delay: 0, options: .curveEaseIn) {
            self.blockView.block = boardBlock.block
            self.blockView.isHidden = false
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    private func updateIsProjected() {
        blockView.alpha = isProjected ? 0.3 : 1
    }

}

private struct BoardBlockViewRepresentable: UIViewRepresentable {

    var isProjected: Bool

    func makeUIView(context: Context) -> BoardBlockView {
        let view = BoardBlockView()
        view.columns = 4
        view.rows = 4
        view.boardBlock = BoardBlock(blockShape: BlockShape.shapes[0], blockRotation: .clockwise0, x: 1, y: 0)
        return view
    }

    func updateUIView(_ uiView: BoardBlockView, context: Context) {
        uiView.isProjected = isProjected
    }

}

#Preview("regular") {
    BoardBlockPreview { params in
        BoardBlockViewRepresentable(isProjected: false)
    }
}

#Preview("projected") {
    BoardBlockPreview { params in
        BoardBlockViewRepresentable(isProjected: true)
    }
}
