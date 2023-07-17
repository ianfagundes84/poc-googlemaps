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
    
    private let databaseManager: DatabaseManagerProtocol?

    init(sharedQueue: SharedQueue = SharedQueue(), databaseManager: DatabaseManagerProtocol = DataManager.instance) {
        self.manager = sharedQueue
        self.databaseManager = databaseManager
        super.init(nibName: nil, bundle: nil)
    }
      
    required init?(coder: NSCoder) {
        self.manager = SharedQueue(databaseManager: DataManager.instance)
        self.databaseManager = DataManager.instance
        super.init(coder: coder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(GMSServices.openSourceLicenseInfo())

           GoogleMapsHelper.initLocationManager(locationManager, delegate: self)

           GoogleMapsHelper.createMap(on: view, locationManager: locationManager, mapView: mapView)
        
            //TODO: - Remove if necessary was for tests propose.
            //Dequeuing only initialize after the
            //first location update and enqueue
            //operation

//           DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 30.0) {
//               self.startDequeue()
//           }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
        mapView.clear()
    }

    func startEnqueue() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while true {
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while true {
                if let item = self?.manager?.dequeue() {
                    print("Date: \(item.date), Location: \(item.location)")
                }
//                Thread.sleep(forTimeInterval: 30)
            }
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let clLocation = locations.last else { return }
        
        let currentDate = Date()
        let location = clLocation.toLocation()
        let timeLocation = TimeLocation(id: IDGenerator.generateUniqueID(), date: currentDate, location: location)
        
        self.manager?.enqueue(timeLocation)
        self.manager?.dequeue()
        
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
