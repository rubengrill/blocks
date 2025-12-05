//
//  BlockForm+Extension.swift
//  Blocks
//
//  Created by Ruben Grill on 01.12.25.
//

import BlocksEngine
import UIKit

extension BlockForm {

    var color: UIColor? {
        UIColor(named: "block-\(rawValue)")
    }

}
