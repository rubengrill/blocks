//
//  BlockForm+Extension.swift
//  Blocks
//
//  Created by Ruben Grill on 01.12.25.
//

import BlocksEngine
import SwiftUI

extension BlockForm {

    var color: Color {
        Color("block-\(rawValue)")
    }

}
