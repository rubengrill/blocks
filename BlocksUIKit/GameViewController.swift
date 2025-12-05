//
//  GameViewController.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 12.03.23.
//

import Combine
import SwiftUI
import UIKit

class GameViewController: UIViewController {

    var gameModel: GameModel? { didSet { updateGameModel() }}

    private lazy var boardView = BoardView()

    private var gameModelCancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(named: "background")
        view.addSubview(boardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        boardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        boardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        boardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        updateGameModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameModel?.start()
    }

    private func updateGameModel() {
        guard isViewLoaded else { return }
        gameModelCancellables.removeAll()
        boardView.gameModel = gameModel
        gameModel?.$isOver
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in self?.showGameOver() }
            .store(in: &gameModelCancellables)
    }

    private func showGameOver() {
        guard let gameModel else { return }
        let vc = UIAlertController(
            title: String(localized: "Game over!"),
            message: String(localized: "Score: \(gameModel.score). Repeat?"),
            preferredStyle: .alert
        )
        vc.addAction(UIAlertAction(title: String(localized: "No"), style: .cancel) { _ in
            self.dismiss(animated: true)
        })
        vc.addAction(UIAlertAction(title: String(localized: "Yes"), style: .default) { _ in
            gameModel.reset()
            gameModel.start()
        })
        present(vc, animated: true)
    }

}

private struct GameViewControllerRepresentable: UIViewControllerRepresentable {

    var gameModel: GameModel

    func makeUIViewController(context: Context) -> GameViewController {
        GameViewController()
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        uiViewController.gameModel = gameModel
    }

}

#Preview {
    GamePreview(target: .UIKit) { params in
        GameViewControllerRepresentable(gameModel: params.gameModel)
    }
}
