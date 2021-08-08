//
//  ExecuteOnlyStorage.swift
//  RunOnce
//
//  Created by Sarris, Aris on 05/02/2021.
//  Copyright © 2021 Sarris, Aris. All rights reserved.
//

import Foundation



protocol ExecuteOnlyStorage1 {
    mutating func set(_ value: Int, _ key: String)
    mutating func set(_ date: Date, _ key: String)
    func getInt(_ key: String) -> Int?
    func getDate(_ key: String) -> Date?
}

extension UserDefaults: ExecuteOnlyStorage1 {
    func getDate(_ key: String) -> Date? {
        if let interval = value(forKey: key) as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }

    func getInt(_ key: String) -> Int? {
        value(forKey: key) as? Int
    }

    func set(_ value: Int, _ key: String) {
        set(value, forKey: key)
    }

    func set(_ date: Date, _ key: String) {
        set(date.timeIntervalSince1970, forKey: key)
    }
}


struct SessionStorage1: ExecuteOnlyStorage1 {

    var backingStore = [String: Any]()

    mutating func set(_ value: Int, _ key: String) {
        backingStore[key] = value
    }

    mutating func set(_ date: Date, _ key: String) {
        backingStore[key] = date
    }

    func getInt(_ key: String) -> Int? {
        backingStore[key] as? Int
    }

    func getDate(_ key: String) -> Date? {
        backingStore[key] as? Date
    }
}
