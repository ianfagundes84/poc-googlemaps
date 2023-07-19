//
//  IDGenerator.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 16/07/23.
//

import Foundation
class IDGenerator {
    static func generateUniqueID() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}
