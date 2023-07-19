//
//  DataManager.swift
//  poc-googlemaps
//
//  Created by Ian Fagundes on 16/07/23.
//

import Foundation
import SQLite
import CoreLocation

protocol DatabaseManagerProtocol {
    func createTable(completion: @escaping (Bool) -> Void)
    func addEntry(entry: TimeLocation, completion: @escaping (String?) -> Void)
    func getAllEntries(completion: @escaping ([TimeLocation]?) -> Void)
    func updateEntry(entryID: String, newEntry: TimeLocation, completion: @escaping (Bool) -> ())
    func deleteEntry(entryID: String, completion: @escaping (Bool) -> Void)
}

class DataManager: DatabaseManagerProtocol {
    static let instance = DataManager()
    private let db: Connection?
    private let queue = DispatchQueue(label: "com.databaseManager.queue", qos: .background)

    private let entries = Table("entries")
    private let id = Expression<String>("id")
    private let date = Expression<Date>("date")
    private let latitude = Expression<Double>("latitude")
    private let longitude = Expression<Double>("longitude")
    private let delivered = Expression<Bool>("delivered")


    private init() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

        do {
            db = try Connection("\(path)/db.sqlite3")
            createTable { success in
                if !success {
                    print("Failed to create table")
                }
            }
        } catch {
            db = nil
            print ("Unable to open database")
        }
    }

    func createTable(completion: @escaping (Bool) -> ()) {
        queue.async {
            do {
                try self.db?.run(self.entries.create(ifNotExists: true) { table in
                    table.column(self.id)
                    table.column(self.date)
                    table.column(self.latitude)
                    table.column(self.longitude)
                    table.column(self.delivered, defaultValue: false)
                })
                completion(true)
            } catch {
                print("Unable to create table")
                completion(false)
            }
        }
    }

    func addEntry(entry: TimeLocation, completion: @escaping (String?) -> ()) {
        queue.async {
            do {
                let insert = self.entries.insert(
                    self.id <- IDGenerator.generateUniqueID(),
                    self.date <- entry.date,
                    self.latitude <- entry.location.latitude,
                    self.longitude <- entry.location.longitude,
                    self.delivered <- false
                )
                let _ = try self.db?.run(insert)
                completion(entry.id)
            } catch {
                print("Cannot insert to database")
                completion(nil)
            }
        }
    }

    func getAllEntries(completion: @escaping ([TimeLocation]?) -> ()) {
        queue.async {
            var entryList = [TimeLocation]()
            do {
                for entry in try self.db!.prepare(self.entries) {
                    entryList.append(TimeLocation(
                        id: entry[self.id],
                        date: entry[self.date],
                        location: Location(latitude: entry[self.latitude], longitude: entry[self.longitude])
                    ))
                }
                completion(entryList)
            } catch {
                print("Cannot get list of entries")
                completion(nil)
            }
        }
    }

    func updateEntry(entryID: String, newEntry: TimeLocation, completion: @escaping (Bool) -> ()) {
        queue.async {
            let entry = self.entries.filter(self.id == entryID)
            do {
                let update = entry.update([
                    self.date <- newEntry.date,
                    self.latitude <- newEntry.location.latitude,
                    self.longitude <- newEntry.location.longitude,
                    self.delivered <- self.delivered
                ])
                if try self.db!.run(update) > 0 {
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print("Update failed: \(error)")
                completion(false)
            }
        }
    }

    func deleteEntry(entryID: String, completion: @escaping (Bool) -> ()) {
        queue.async {
            let entry = self.entries.filter(self.id == entryID && self.delivered == true)
            do {
                if try self.db!.run(entry.delete()) > 0 {
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print("Delete failed: \(error)")
                completion(false)
            }
        }
    }
}
