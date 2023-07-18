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
    var manager: SharedQueue?
    var isRunning = true
    var timer: DispatchSourceTimer?
    private let databaseManager: DataManager = DataManager.instance

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

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - GPS + layout

        GoogleMapsHelper.shared.createMap(on: view)
        GoogleMapsHelper.shared.delegate = self

        setupLayout()
        view.bringSubviewToFront(btPanic)

        // MARK: - QUEUE

        manager = SharedQueue(databaseManager: databaseManager)
        startEnqueue()
        // Dequeuing only initialize after the
        // first location update and enqueue
        // operation
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 30) {
            self.startDequeue()
        }
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

    func startEnqueue() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            while self?.isRunning ?? false {
                guard let clLocation = GoogleMapsHelper.shared.locationManager.location else { return }
                let currentDate = Date()

                let location = clLocation.toLocation()

                let timeLocation = TimeLocation(id: IDGenerator.generateUniqueID(), date: currentDate, location: location)
                self?.manager?.enqueue(timeLocation)

                Thread.sleep(forTimeInterval: 30)
            }
        }
    }

    func startDequeue() {
        let dequeueQueue = DispatchQueue(label: "com.dequeue.queue", qos: .utility)
        dequeueQueue.async { [weak self] in
            while self?.isRunning ?? false {
                switch self?.manager?.dequeue() {
                case let .success(item):
                    // print("Date: \(item.date), Location: \(item.location)")
                    break
                case let .failure(error):
                    break
                case .none:
                    break
                }
            }
        }
    }

    // MARK: - Actions - Panic button rules and treatment

    @IBAction func panicButtonPressed(_ sender: UIButton) {
        GoogleMapsHelper.shared.panicButton()
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
