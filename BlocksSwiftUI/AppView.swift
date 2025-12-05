//
//  AppView.swift
//  Blocks
//
//  Created by Ruben Grill on 19.11.25.
//

import SwiftUI

struct AppView: View {

    @StateObject
    private var gameModel = GameModel(columns: 10, rows: 20, target: .SwiftUI)

    @State
    private var showGame = false

    @AppStorage("AppView.showProjectedBoardBlock")
    private var showProjectedBoardBlock = false

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Toggle("Project block", isOn: $showProjectedBoardBlock)
                .fixedSize()
                .tint(.accentColor)

            Button("Start") {
                gameModel.reset()
                gameModel.showProjectedBoardBlock = showProjectedBoardBlock
                showGame = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color("background"))
        .fullScreenCover(isPresented: $showGame) {
            GameView(gameModel: gameModel)
        }
    }

}

#Preview {
    AppView()
}
