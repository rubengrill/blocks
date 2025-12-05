//
//  AppViewController.swift
//  BlocksUIKit
//
//  Created by Ruben Grill on 26.02.23.
//

import UIKit

class AppViewController: UIViewController {

    private let gameModel = GameModel(columns: 10, rows: 20, target: .UIKit)

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()

    private lazy var showProjectedBoardBlockStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()

    private lazy var showProjectedBoardBlockLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Project block")
        return label
    }()

    private lazy var showProjectedBoardBlockSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .tintColor
        toggle.addTarget(self, action: #selector(onToggleShowProjectedBoardBlockSwitch), for: .valueChanged)
        return toggle
    }()

    private lazy var startGameButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = .borderedProminent()
        button.configuration?.title = String(localized: "Start")
        button.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(named: "background")
        view.addSubview(containerStackView)

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        containerStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        containerStackView.addArrangedSubview(showProjectedBoardBlockStackView)
        containerStackView.addArrangedSubview(startGameButton)

        showProjectedBoardBlockStackView.addArrangedSubview(showProjectedBoardBlockLabel)
        showProjectedBoardBlockStackView.addArrangedSubview(showProjectedBoardBlockSwitch)

        showProjectedBoardBlockSwitch.isOn = UserDefaults.standard.bool(forKey: "AppViewController.showProjectedBlock")
    }

    @objc
    private func startGame() {
        gameModel.reset()
        gameModel.showProjectedBoardBlock = showProjectedBoardBlockSwitch.isOn
        let vc = GameViewController()
        vc.gameModel = gameModel
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc
    private func onToggleShowProjectedBoardBlockSwitch() {
        UserDefaults.standard.set(showProjectedBoardBlockSwitch.isOn, forKey: "AppViewController.showProjectedBlock")
    }

}

#Preview {
    AppViewController()
}
