//
//  GridGuide.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 13.03.23.
//

import UIKit

class GridGuide {

    weak var view: UIView?

    var rows: Int = 0 {
        didSet {
            if oldValue != rows {
                updateRowLayoutGuides()
            }
        }
    }

    var columns: Int = 0 {
        didSet {
            if oldValue != columns {
                updateColumnLayoutGuides()
            }
        }
    }

    private(set) var rowLayoutGuides: [UILayoutGuide] = []
    private(set) var columnLayoutGuides: [UILayoutGuide] = []

    init(view: UIView) {
        self.view = view
    }

    private func updateRowLayoutGuides() {
        guard let view else { return }

        rowLayoutGuides.forEach { view.removeLayoutGuide($0) }

        let layoutGuides = (0 ..< rows).map { _ in UILayoutGuide() }

        for (index, layoutGuide) in layoutGuides.enumerated() {
            view.addLayoutGuide(layoutGuide)

            let topOffset = view.topAnchor.anchorWithOffset(to: layoutGuide.topAnchor)

            layoutGuide.identifier = "Row \(index)"
            layoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            layoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            layoutGuide.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1 / CGFloat(rows)).isActive = true
            topOffset.constraint(equalTo: view.heightAnchor, multiplier: CGFloat(index) / CGFloat(rows)).isActive = true
        }

        self.rowLayoutGuides = layoutGuides
    }

    private func updateColumnLayoutGuides() {
        guard let view else { return }

        columnLayoutGuides.forEach { view.removeLayoutGuide($0) }

        let layoutGuides = (0 ..< columns).map { _ in UILayoutGuide() }

        for (index, layoutGuide) in layoutGuides.enumerated() {
            view.addLayoutGuide(layoutGuide)

            let leadingOffset = view.leadingAnchor.anchorWithOffset(to: layoutGuide.leadingAnchor)

            layoutGuide.identifier = "Column \(index)"
            layoutGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            layoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            layoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 / CGFloat(columns)).isActive = true
            leadingOffset.constraint(equalTo: view.widthAnchor, multiplier: CGFloat(index) / CGFloat(columns)).isActive = true
        }

        self.columnLayoutGuides = layoutGuides
    }

}
