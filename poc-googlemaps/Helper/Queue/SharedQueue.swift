//
//  SharedQueue.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 15/07/23.
//

import Foundation

enum QueueError: Error {
    case dequeueFailed
}

protocol Queue {
    associatedtype Position
    func enqueue(_ element: Position)
    func dequeue() -> Result<Position, QueueError>
}

class SharedQueue: Queue {
    typealias Position = TimeLocation
    
    private let databaseManager: DatabaseManagerProtocol

    init(databaseManager: DatabaseManagerProtocol = DataManager.instance) {
        self.databaseManager = databaseManager

        self.databaseManager.getAllEntries { entries in
            self.queue = entries ?? []
            for _ in self.queue {
                self.semaphoreQueue.signal()
            }
        }
    }

    private var queue = [Position]()
    private let semaphoreQueue = DispatchSemaphore(value: 0)
    private let semaphoreLock = DispatchSemaphore(value: 1)

    func enqueue(_ element: Position) {
        semaphoreLock.wait()
            
        databaseManager.getAllEntries { [weak self] entries in
            if let entries = entries, entries.contains(where: { $0.id == element.id }) {
                self?.semaphoreLock.signal()
            } else {
                self?.queue.append(element)
            
                self?.databaseManager.addEntry(entry: element) { id in
                    guard let id = id else {
                        print("ERROR")
                        return }
                    print("Enqueue date: \(element.date.asLocalGMT) id: \(id)")
                }
            
                self?.semaphoreLock.signal()
                self?.semaphoreQueue.signal()
            }
        }
    }

    
    func dequeue() -> Result<Position, QueueError> {
        semaphoreQueue.wait()
        semaphoreLock.wait()

        guard !queue.isEmpty else {
            semaphoreLock.signal()
            return .failure(.dequeueFailed)
        }

        let dequeuedElement = queue.removeFirst()
        
        print("Dequeue date: \(dequeuedElement.date.asLocalGMT) id: \(dequeuedElement.id)")
                
        semaphoreLock.signal()
        return .success(dequeuedElement)
    }
    
    func requeueUndelivered() {
        databaseManager.getAllUndeliveredEntries { entries in
            if let entries = entries {
                for entry in entries {
                    self.enqueue(entry)
                }
            }
        }
    }
}
