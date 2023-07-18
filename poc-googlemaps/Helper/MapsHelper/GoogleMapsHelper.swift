import GoogleMaps
import UIKit

enum LocationError: Error {
    case requestNotAuthorized
    case otherError(String)
}

protocol GoogleMapsHelperDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
    func didFailWithError(_ error: Error)
}

class GoogleMapsHelper: NSObject, CLLocationManagerDelegate {
    static let shared = GoogleMapsHelper()

    var locationManager = CLLocationManager()
    var mapView: GMSMapView?

    var isPanicButtonPressed: Bool = false

    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevel: Float = 10.0

    weak var delegate: GoogleMapsHelperDelegate?

    override private init() {
        super.init()
        initLocationManager(locationManager, delegate: self)
    }

    func initLocationManager(_ locationManager: CLLocationManager, delegate: CLLocationManagerDelegate) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = delegate as? CLLocationManagerDelegate
        if #available(iOS 13.0, *) {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    func createMap(on view: UIView) {
        guard let location = locationManager.location else { return }
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView?.settings.myLocationButton = true
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.isMyLocationEnabled = true

        view.addSubview(mapView!)
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func clearMapView() {
        mapView?.clear()
    }

    func updateCameraBearing(bearing: Double, mapView: GMSMapView) {
        let camera = mapView.camera
        let updatedCamera = GMSCameraPosition.camera(withLatitude: camera.target.latitude,
                                                     longitude: camera.target.longitude,
                                                     zoom: camera.zoom,
                                                     bearing: bearing,
                                                     viewingAngle: camera.viewingAngle)
        mapView.camera = updatedCamera
    }

    func updateCameraPositionAndBearing(location: CLLocation, locationManager: CLLocationManager, bearing: CLLocationDirection, mapView: GMSMapView) {
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel,
                                              bearing: bearing,
                                              viewingAngle: 0)
        mapView.animate(to: camera)
    }

    func handle(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let accuracy = manager.accuracyAuthorization
        switch accuracy {
        case .fullAccuracy:
            print("Location accuracy is precise.")
        case .reducedAccuracy:
            print("Location accuracy is not precise.")
        @unknown default:
            fatalError()
        }

        // Handle authorization status
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways:
//            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            if manager.allowsBackgroundLocationUpdates {
                manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                manager.distanceFilter = 500
                manager.startUpdatingLocation()
            }
//            }
        case .authorizedWhenInUse:
            print("Location status is OK.")
        @unknown default:
            fatalError()
        }
    }
}

// MARK: - Panic Handler

extension GoogleMapsHelper {
    func panicButton() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            delegate?.didFailWithError(LocationError.requestNotAuthorized)
        }
    }
}

// MARK: - GoogleMapsHelper delegate:

extension GoogleMapsHelper {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let zoomLevel = manager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView?.camera = camera

        if let location = locations.first {
            delegate?.didUpdateLocation(location)

            if isPanicButtonPressed {
                manager.stopUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.didFailWithError(error)
    }
}
