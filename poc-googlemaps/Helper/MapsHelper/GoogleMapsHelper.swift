import GoogleMaps
import UIKit

struct GoogleMapsHelper {
    static let NewYork = CLLocation(latitude: -23.730610, longitude: -46.935242)

    static var preciseLocationZoomLevel: Float = 15.0
    static var approximateLocationZoomLevel: Float = 10.0

    static func initLocationManager(_ locationManager: CLLocationManager, delegate: UIViewController) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = delegate as? CLLocationManagerDelegate
    }

    static func createMap(on view: UIView, locationManager: CLLocationManager, mapView: GMSMapView) {
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: NewYork.coordinate.latitude,
                                              longitude: NewYork.coordinate.longitude,
                                              zoom: zoomLevel)
        var mapView = mapView
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true

        view.addSubview(mapView)
    }

    static func didUpdateLocations(_ locations: [CLLocation], locationManager: CLLocationManager, mapView: GMSMapView) {
        let location: CLLocation = locations.last!
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView.camera = camera
    }

    static func updateCameraBearing(bearing: Double, mapView: GMSMapView) {
        let camera = mapView.camera
        let updatedCamera = GMSCameraPosition.camera(withLatitude: camera.target.latitude,
                                                     longitude: camera.target.longitude,
                                                     zoom: camera.zoom,
                                                     bearing: bearing,
                                                     viewingAngle: camera.viewingAngle)
        mapView.camera = updatedCamera
    }

    static func updateCameraPositionAndBearing(location: CLLocation, locationManager: CLLocationManager, bearing: CLLocationDirection, mapView: GMSMapView) {
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel,
                                              bearing: bearing,
                                              viewingAngle: 0)
        mapView.animate(to: camera)
    }
    
    static func handle(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
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
