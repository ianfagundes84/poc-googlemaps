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
    var manager: SharedQueue = SharedQueue()

    var mapView: GMSMapView = GMSMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        startEnqueue()
        startDequeue()

        print(GMSServices.openSourceLicenseInfo())

        GoogleMapsHelper.initLocationManager(locationManager, delegate: self)

        GoogleMapsHelper.createMap(on: view, locationManager: locationManager, mapView: mapView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.clear()
    }

    func startEnqueue() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in

            for _ in 1 ... 100 {
                guard let location = self?.locationManager.location else { return }
                let currentDate = Date()
                //                let timeLocation = [TimeLocation(date: currentDate, location: location), TimeLocation(date: currentDate, location: location), TimeLocation(date: currentDate, location: location)]
                let timeLocation = [TimeLocation(date: currentDate, location: location)]
                self?.manager.enqueue(timeLocation)
                sleep(30)
            }
        }
    }

    func startDequeue() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while true {
                for i in 1 ... 10 {
//                    print("init for step: \(i)")
                    var dequeuedItem: TimeLocation?
                    repeat {
                        dequeuedItem = self?.manager.dequeue()
                        if let item = dequeuedItem {
                            print("Date: \(item.date), Location: \(item.location)")
                        }
                    } while dequeuedItem == nil
//                    print("queue still not nil -> next for step: \(i + 1)")
                }
                sleep(30)
            }
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        GoogleMapsHelper.didUpdateLocations(locations, locationManager: locationManager, mapView: mapView)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        GoogleMapsHelper.handle(manager, didChangeAuthorization: status)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}
