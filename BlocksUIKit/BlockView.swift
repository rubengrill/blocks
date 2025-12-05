//
//  BlockView.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 11.03.23.
//

import BlocksEngine
import SwiftUI
import UIKit

class BlockView: UIView {

    var block: Block? {
        didSet {
            if oldValue !== block {
                updateBlock()
            }
        }
    }

    private lazy var gridGuide = GridGuide(view: self)

    private func updateBlock() {
        subviews.forEach { $0.removeFromSuperview() }

        guard let block else { return }

        gridGuide.columns = block.size
        gridGuide.rows = block.size

        for x in block.columnBounds {
            for y in block.rowBounds {
                guard block.data[y][x] > 0 else { continue }
                let brickView = BrickView()
                addSubview(brickView)
                brickView.translatesAutoresizingMaskIntoConstraints = false
                brickView.backgroundColor = block.blockForm.color
                NSLayoutConstraint.activate([
                    brickView.leftAnchor.constraint(equalTo: gridGuide.columnLayoutGuides[x].leftAnchor),
                    brickView.rightAnchor.constraint(equalTo: gridGuide.columnLayoutGuides[x].rightAnchor),
                    brickView.topAnchor.constraint(equalTo: gridGuide.rowLayoutGuides[y].topAnchor),
                    brickView.bottomAnchor.constraint(equalTo: gridGuide.rowLayoutGuides[y].bottomAnchor),
                ])
            }
        }
    }

}

private struct BlockViewRepresentable: UIViewRepresentable {

    var block: Block

    func makeUIView(context: Context) -> BlockView {
        BlockView()
    }

    func updateUIView(_ uiView: BlockView, context: Context) {
        uiView.block = block
    }

}

#Preview {
    BlockPreview { params in
        BlockViewRepresentable(block: params.block)
    }
}
