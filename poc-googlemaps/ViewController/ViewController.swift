//
//  ViewController.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 14/07/23.
//

import CoreLocation
import GoogleMaps
import TinyConstraints
import UIKit

class ViewController: UIViewController {
    
    var isRunning = true
    var timer: DispatchSourceTimer?
    
    var queueManager: QueueManagerProtocol?

    var canPressPanicButton: Bool = true

    lazy var btPanic: UIButton = {
        let bt = UIButton()
        bt.backgroundColor = .red

        bt.setTitle("Panic", for: .normal)
        bt.setTitleColor(.white, for: .normal)

        bt.layer.shadowColor = UIColor.black.cgColor
        bt.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        bt.layer.shadowOpacity = 0.2
        bt.layer.shadowRadius = 4.0
        bt.layer.masksToBounds = false

        return bt
    }()

    // MARK: - Life cycle
    
    init(databaseManager: DatabaseManagerProtocol, apiManager: APISenderProtocol) {
        let sharedQueue = SharedQueue(databaseManager: databaseManager)
        self.queueManager = QueueManager(
            sharedQueue: sharedQueue,
            databaseManager: databaseManager,
            apiManager: apiManager
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let databaseManager = DataManager.instance
        let apiManager = APISender()
        let sharedQueue = SharedQueue(databaseManager: databaseManager)
        self.queueManager = QueueManager(
            sharedQueue: sharedQueue,
            databaseManager: databaseManager,
            apiManager: apiManager
        )
        super.init(coder: coder)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - GPS + layout

        GoogleMapsHelper.shared.createMap(on: view)
        GoogleMapsHelper.shared.delegate = self

        setupLayout()
        view.bringSubviewToFront(btPanic)

        // MARK: - QUEUE
        queueManager?.startQueueManagement()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btPanic.layer.cornerRadius = btPanic.frame.height / 2
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GoogleMapsHelper.shared.stopUpdatingLocation()
        GoogleMapsHelper.shared.clearMapView()
        isRunning = false
    }

    // MARK: - Functions

    func showPanicButtonAlert() {
        let alertController = UIAlertController(title: "Pânico já pressionado", message: "Aguarde 2 segundos para pressionar o botão novamente.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Actions - Panic button rules and treatment

    @IBAction func panicButtonPressed(_ sender: UIButton) {
        if canPressPanicButton {
            canPressPanicButton = false
            GoogleMapsHelper.shared.panicButton()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.canPressPanicButton = true
            }
        } else {
            showPanicButtonAlert()
        }
    }

    deinit {
        timer?.cancel()
    }
}

// MARK: - Conforming with CLLocation manager delegate

extension ViewController: GoogleMapsHelperDelegate {
    func didUpdateLocation(_ location: CLLocation) {
        if GoogleMapsHelper.shared.isPanicButtonPressed {
            print("Panic location: \(location)")
        }
    }

    func didFailWithError(_ error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
}

// MARK: - Layout to be modified.

extension ViewController: CLLocationManagerDelegate {
    func setupLayout() {
        btPanic.addTarget(self, action: #selector(panicButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(btPanic)

        btPanic.height(50)
        btPanic.width(50)
        btPanic.trailingToSuperview(offset: 16)
        btPanic.topToSuperview(offset: 42)
    }
}
