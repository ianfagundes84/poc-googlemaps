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

    private var queue = [Position]()
    private let semaphoreQueue = DispatchSemaphore(value: 0)
    private let semaphoreLock = DispatchSemaphore(value: 1)

    func enqueue(_ element: Position) { 
        semaphoreLock.wait()
        queue.append(element)
        semaphoreLock.signal()
        semaphoreQueue.signal()
    }

    func dequeue() -> Position? {
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
