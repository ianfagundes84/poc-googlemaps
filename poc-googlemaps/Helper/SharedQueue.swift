//
//  SharedQueue.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 15/07/23.
//

import Foundation

protocol Queue {
    associatedtype Position
    func enqueue(_ element: Position)
    func dequeue() -> Position?
}

class SharedQueue: Queue {
    typealias Position = TimeLocation
    
    private let databaseManager: DatabaseManagerProtocol

    init(databaseManager: DatabaseManagerProtocol) {
        self.databaseManager = databaseManager
        
        self.databaseManager.getAllEntries { entries in
            self.queue = entries ?? []
        }
    }

    private var queue = [Position]()
    private let semaphoreQueue = DispatchSemaphore(value: 0)
    private let semaphoreLock = DispatchSemaphore(value: 1)

    func enqueue(_ element: Position) {
        semaphoreLock.wait()
        
        queue.append(element)
        
        databaseManager.addEntry(entry: element) { id in
            // Optionally, you can handle the returned id here.
            print(id)
        }
        
        semaphoreLock.signal()
        semaphoreQueue.signal()
    }

    func dequeue() -> Position? {
        semaphoreQueue.wait()
        semaphoreLock.wait()
        defer { semaphoreLock.signal() }
        if !queue.isEmpty {

            let dequeuedElement = queue.removeFirst()
            
            if let dequeuedElementId = dequeuedElement.id {
                databaseManager.deleteEntry(entryID: dequeuedElementId) { success in
                    // Optionally, you can handle the success of the deletion here.
                }
            }
            
            return dequeuedElement
        } else {
            return nil
        }
    }
}
