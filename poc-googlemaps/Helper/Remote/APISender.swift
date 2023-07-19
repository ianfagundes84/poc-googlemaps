//
//  APISender.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 19/07/23.
//

import Foundation

protocol APISenderProtocol {
    func sendPackage(entry: TimeLocation, completion: @escaping (Result<Bool, Error>) -> Void)
}

class APISender: APISenderProtocol {
    func sendPackage(entry: TimeLocation, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "http://localhost:3000/timeLocation") else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json = entry.jsonRepresentation

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
            }

            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
                completion(response.statusCode == 200 ? .success(true) : .failure(NSError(domain: "", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code: \(response.statusCode)"])))
            }
        }
        task.resume()
    }
}
