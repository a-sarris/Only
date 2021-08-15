//
//  ExecuteOnlyStorage.swift
//  RunOnce
//
//  Created by Sarris, Aris on 05/02/2021.
//  Copyright © 2021 Sarris, Aris. All rights reserved.
//

import Foundation



public protocol OnlyStorage {
    mutating func set(_ value: Int, _ key: String)
    mutating func set(_ date: Date, _ key: String)
    func getInt(_ key: String) -> Int?
    func getDate(_ key: String) -> Date?
}

extension UserDefaults: OnlyStorage {
    public func getDate(_ key: String) -> Date? {
        if let interval = value(forKey: key) as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        return nil
    }

    public func getInt(_ key: String) -> Int? {
        value(forKey: key) as? Int
    }

    public func set(_ value: Int, _ key: String) {
        set(value, forKey: key)
    }

    public func set(_ date: Date, _ key: String) {
        set(date.timeIntervalSince1970, forKey: key)
    }
}


public struct OnlySessionStorage: OnlyStorage {

    var backingStore = [String: Any]()


    public init() {}

    public mutating func set(_ value: Int, _ key: String) {
        backingStore[key] = value
    }

    public mutating func set(_ date: Date, _ key: String) {
        backingStore[key] = date
    }

    public func getInt(_ key: String) -> Int? {
        backingStore[key] as? Int
    }

    public func getDate(_ key: String) -> Date? {
        backingStore[key] as? Date
    }
}
