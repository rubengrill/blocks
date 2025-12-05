//
//  Brick.swift
//  BlocksEngine
//
//  Created by Ruben Grill on 10.04.23.
//

import Foundation

public struct Brick: Identifiable, Hashable {

    public var id = UUID()
    public var blockForm: BlockForm

    public init(blockForm: BlockForm) {
        self.blockForm = blockForm
    }

}
