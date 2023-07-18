//
//  ViewController.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 14/07/23.
//

import CoreLocation
import GoogleMaps
import UIKit

class ViewController: UIViewController {
    var locationManager: CLLocationManager = CLLocationManager()
    var manager: SharedQueue?
    var mapView: GMSMapView = GMSMapView()
    var isRunning = true
    var timer: DispatchSourceTimer?
    private let databaseManager: DataManager = DataManager.instance

    override func viewDidLoad() {
        super.viewDidLoad()
        print(GMSServices.openSourceLicenseInfo())

        manager = SharedQueue(databaseManager: databaseManager)

        GoogleMapsHelper.initLocationManager(locationManager, delegate: self)

        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }

        GoogleMapsHelper.createMap(on: view, locationManager: locationManager, mapView: mapView)

        startEnqueue()

        // Dequeuing only initialize after the
        // first location update and enqueue
        // operation
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 30) {
            self.startDequeue()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
        mapView.clear()
        isRunning = false
    }

    func startEnqueue() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while self?.isRunning ?? false {
                guard let clLocation = self?.locationManager.location else { return }
                let currentDate = Date()

                let location = clLocation.toLocation()

                let timeLocation = TimeLocation(id: IDGenerator.generateUniqueID(), date: currentDate, location: location)
                self?.manager?.enqueue(timeLocation)

                Thread.sleep(forTimeInterval: 30)
            }
        }
    }

    func startDequeue() {
        let dequeueQueue = DispatchQueue(label: "com.dequeue.queue", qos: .userInitiated)
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
    
    deinit {
        timer?.cancel()
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let clLocation = locations.last else { return }

        let currentDate = Date()
        let location = clLocation.toLocation()
        let timeLocation = TimeLocation(id: IDGenerator.generateUniqueID(), date: currentDate, location: location)

        let bearing: CLLocationDirection = clLocation.course >= 0 ? clLocation.course : 0.0
        GoogleMapsHelper.updateCameraPositionAndBearing(location: clLocation, locationManager: manager, bearing: bearing, mapView: mapView)
        GoogleMapsHelper.didUpdateLocations(locations, locationManager: locationManager, mapView: mapView)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        GoogleMapsHelper.handle(manager, didChangeAuthorization: status)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error.localizedDescription)")
    }
}
