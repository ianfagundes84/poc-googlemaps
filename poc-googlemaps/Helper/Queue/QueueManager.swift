//
//  QueueManager.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 19/07/23.
//

import Foundation

protocol QueueManagerProtocol {
    func startQueueManagement()
}

class QueueManager: QueueManagerProtocol {
    
    private let sharedQueue: SharedQueueProtocol
    private let databaseManager: DatabaseManagerProtocol
    private let apiManager: APISenderProtocol
    
    init(sharedQueue: SharedQueueProtocol, databaseManager: DatabaseManagerProtocol, apiManager: APISenderProtocol) {
        self.sharedQueue = sharedQueue
        self.databaseManager = databaseManager
        self.apiManager = apiManager
    }
    
    func startQueueManagement() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            while true {
                self?.requeueUndelivered()
                self?.processQueue()
                Thread.sleep(forTimeInterval: 5.0)
            }
        }
    }
    
    private func requeueUndelivered() {
        self.databaseManager.getAllUndeliveredEntries { entries in
            entries?.forEach { entry in
                self.sharedQueue.enqueue(entry)
            }
        }
    }
    
    private func processQueue() {
        switch sharedQueue.dequeue() {
        case .success(let entry):
            self.apiManager.sendPackage(entry: entry) { result in
                switch result {
                case .success:
                    self.databaseManager.updateDeliveryStatus(entryID: entry.id, delivered: true) { success in
                        if success {
                            self.databaseManager.deleteEntry(entryID: entry.id) { _ in }
                        }
                    }
                case .failure:
                    self.databaseManager.updateDeliveryStatus(entryID: entry.id, delivered: false) { _ in }
                }
            }
        case .failure:
            print("No entries in the queue to process.")
        }
    }
}
