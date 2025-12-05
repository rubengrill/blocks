//
//  BrickView.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 26.03.23.
//

import UIKit

class BrickView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .tintColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

#Preview {
    let view = BrickView()
    view.widthAnchor.constraint(equalToConstant: 40).isActive = true
    view.heightAnchor.constraint(equalToConstant: 40).isActive = true
    return view
}
