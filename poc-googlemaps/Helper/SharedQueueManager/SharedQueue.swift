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
        
        queue.append(element)
        
        databaseManager.addEntry(entry: element) { id in
            guard let id = id else {
                print("ERROR")
                return }
            print("Enqueue date: \(element.date.asLocalGMT) id: \(id)")
        }
        
        semaphoreLock.signal()
        semaphoreQueue.signal()
    }
    
    func dequeue() -> Result<Position, QueueError> {
        semaphoreQueue.wait()
        semaphoreLock.wait()

        guard !queue.isEmpty else {
            semaphoreLock.signal()
            return .failure(.dequeueFailed)
        }

        let dequeuedElement = queue.removeFirst()

        databaseManager.deleteEntry(entryID: dequeuedElement.id) { success in
                // TODO: - handle with success deletion
            print("Dequeue date: \(dequeuedElement.date.asLocalGMT) id: \(dequeuedElement.id)")
            }
            
        semaphoreLock.signal()
        return .success(dequeuedElement)
    }
}
