//
//  SharedQueue.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 15/07/23.
//

import Foundation

protocol Queue {
    associatedtype Position
    func enqueue(_ element: [Position])
    func dequeue() -> Position?
}

class SharedQueue: Queue {
    typealias Position = TimeLocation

    private var queue = [TimeLocation]()
    private let semaphoreQueue = DispatchSemaphore(value: 0)
    private let semaphoreLock = DispatchSemaphore(value: 1)

    func enqueue(_ element: [TimeLocation]) {
        semaphoreLock.wait()
        queue.append(contentsOf: element)
        semaphoreLock.signal()
        semaphoreQueue.signal()
    }

    func dequeue() -> TimeLocation? {
        semaphoreQueue.wait()
        semaphoreLock.wait()
        defer { semaphoreLock.signal() } 
        if !queue.isEmpty {
            return queue.removeFirst()
        } else {
            return nil
        }
    }
}

