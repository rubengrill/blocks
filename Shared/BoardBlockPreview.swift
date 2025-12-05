//
//  BoardBlockPreview.swift
//  Blocks
//
//  Created by Ruben Grill on 29.11.25.
//

import SwiftUI

struct BoardBlockPreviewParams {
    var gridSize: CGSize
}

struct BoardBlockPreview<Content: View>: View {

    @ViewBuilder
    var content: (BoardBlockPreviewParams) -> Content

    private let gridSize = CGSize(width: 300, height: 300)

    var body: some View {
        content(BoardBlockPreviewParams(gridSize: gridSize))
            .frame(width: gridSize.width, height: gridSize.height, alignment: .center)
            .overlay {
                Rectangle()
                    .strokeBorder(.tint, lineWidth: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color("background"))
    }

}

#Preview {
    BoardBlockPreview { _ in
        Text("content")
    }
}
