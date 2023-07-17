//
//  IDGenerator.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 16/07/23.
//

import Foundation
struct IDGenerator {
    static func generateUniqueID() -> Int64 {
        let currentDate = Date()
        let id = Int64(currentDate.timeIntervalSince1970 * 1000)
        return id
    }
}
