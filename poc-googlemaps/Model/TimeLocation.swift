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
    let delivered: Bool
    
    init(id: String, date: Date, location: Location, delivered: Bool) {
        self.id = id
        self.date = date
        self.location = location
        self.delivered = delivered 
    }

}

struct Location {
    let latitude: Double
    let longitude: Double

    func convertToLocation(from clLocation: CLLocation) -> Location {
        return Location(latitude: clLocation.coordinate.latitude, longitude: clLocation.coordinate.longitude)
    }
}

extension TimeLocation {
    var jsonRepresentation: [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: self.date)

        let json: [String: Any] = [
            "id": self.id,
            "date": dateString,
            "location": [
                "latitude": self.location.latitude,
                "longitude": self.location.longitude,
            ],
        ]

        return json
    }
}
