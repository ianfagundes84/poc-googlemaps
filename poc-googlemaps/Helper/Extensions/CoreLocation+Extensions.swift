//
//  CoreLocation+Extensions.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 16/07/23.
//

import Foundation
import CoreLocation

extension CLLocation {
    func toLocation() -> Location {
        return Location(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
    }
}
