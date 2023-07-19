//
//  Date+Extensions.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 18/07/23.
//

import Foundation
extension Date {
    var asLocalGMT: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: self)
    }
}

