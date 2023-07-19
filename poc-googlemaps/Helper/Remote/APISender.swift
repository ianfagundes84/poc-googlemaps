//
//  APISender.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 19/07/23.
//

import Foundation

class APISender {
    static let instance = APISender()

    private init() { }

    func sendData(timeLocation: TimeLocation, completion: @escaping (Bool) -> Void) {

        guard let url = URL(string: "http://localhost:3000/timeLocation") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "id": timeLocation.id,
            "date": timeLocation.date,
            "location": [
                "latitude": timeLocation.location.latitude,
                "longitude": timeLocation.location.longitude
            ]
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            if let error = error {
                print("Error took place \(error)")
                return
            }

            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
                if response.statusCode == 200 {
                    // On success, update delivery status in the database
                    DataManager.instance.updateDeliveryStatus(entryID: timeLocation.id, delivered: true) { success in
                        if success {
                            print("Delivery status updated successfully.")
                        } else {
                            print("Failed to update delivery status.")
                        }
                    }
                } else {
                    print("Server returned status code: \(response.statusCode)")
                }
                completion(response.statusCode == 200)
            }
        }
        task.resume()
    }
}
