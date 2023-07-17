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

    init(databaseManager: DatabaseManagerProtocol = DataManager.instance) {
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
            // TODO: - Handle with deletion.
            print(id)
        }
        
        semaphoreLock.signal()
        semaphoreQueue.signal()
    }

    func dequeue() -> Position? {
        semaphoreQueue.wait() // Wait here till an item is available.
        semaphoreLock.wait()
        var dequeuedElement: Position? = nil
        if !queue.isEmpty {

            dequeuedElement = queue.removeFirst()
            
            if let dequeuedElementId = dequeuedElement?.id {
                databaseManager.deleteEntry(entryID: dequeuedElementId) { success in
                    // TODO: - handle with success deletion
                }
            }
        }
        semaphoreLock.signal()
        return dequeuedElement
    }
}
