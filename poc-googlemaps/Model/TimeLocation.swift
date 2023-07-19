//
//  TimeLocation.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 15/07/23.
//

import CoreLocation
import Foundation

struct TimeLocation {
    let id: String
    let date: Date
    let location: Location
}

struct Location {
    let latitude: Double
    let longitude: Double

    func convertToLocation(from clLocation: CLLocation) -> Location {
        return Location(latitude: clLocation.coordinate.latitude, longitude: clLocation.coordinate.longitude)
    }
}
