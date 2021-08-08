//
//  ExecuteOnly.swift
//  RunOnce
//
//  Created by Sarris, Aris on 05/02/2021.
//  Copyright © 2021 Sarris, Aris. All rights reserved.
//

import Foundation

enum Keys: String, ExecuteOnlyKey {
    case key
}

typealias ExecuteOnlyKey = RawRepresentable & CaseIterable

enum Frequency<T: ExecuteOnlyKey> where T.RawValue == String {
    case once(T)
    case oncePerSession(T)
    case ifTimePassed(T, DispatchTimeInterval)
    case `if`(() -> Bool)
    case every(T, times: Int)
}

class ExecuteOnly<T: ExecuteOnlyKey> where T.RawValue == String {

    private var persistentStorage: ExecuteOnlyStorage1
    private var sessionStorage: ExecuteOnlyStorage1
    private let dateProvider: () -> Date
    private let profile: String

    @discardableResult
    convenience init(_ profile: String = "com.executeOnly",
         _ frequency: Frequency<T>,
         _ block: ()->()) {

        self.init(with: profile, frequency: frequency, block: block)
    }

    @discardableResult
    required init(with profile: String = "com.executeOnly",
         persistentStorage: ExecuteOnlyStorage1 = UserDefaults.standard,
         sessionStorage: ExecuteOnlyStorage1 = SessionStorage1(),
         frequency: Frequency<T>,
         currentDateProvider: @escaping () -> Date = { Date() },
         block: () -> ()) {
        self.dateProvider = currentDateProvider
        self.persistentStorage = persistentStorage
        self.sessionStorage = sessionStorage
        self.profile = profile
        //let keys = T.allCases.map{ T.name() + $0.rawValue }
        //let storedKeys = storage.get(profile) ?? ExecuteOnlyModel()
        var didRun = false
        if self.shouldExecute(frequency) {
            block()
            didRun = true
        }
        updateKeysIfNeeded(frequency, didExecute: didRun)
    }

    private func shouldExecute(_ frequency: Frequency<T>) -> Bool {
        switch frequency {
        case .once(let key):
            return persistentStorage.getInt(compositeKey(key)) == nil
        case .if(let control):
            return control()
        case .ifTimePassed(let key, let timeLimit):
            guard let value = persistentStorage.getDate(compositeKey(key)) else { return true }
            return value.advanced(by: timeLimit.toDouble()) < dateProvider()
        case .oncePerSession(let key):
            return sessionStorage.getInt(compositeKey(key)) == nil
        case .every(let key, let times):
            let timesExecuted = persistentStorage.getInt(compositeKey(key)) ?? 0
            return timesExecuted == 0 || (timesExecuted + 1) % times == 0
        }
    }

    private func updateKeysIfNeeded (_ frequency: Frequency<T>, didExecute: Bool) {
        switch (frequency, didExecute) {
        case (.once, false), (.ifTimePassed, false), (.if, false), (.oncePerSession, false):
            break
        case (.once, true):
            updateKeys(frequency)
        case (.ifTimePassed, true):
            updateKeys(frequency)
        case (.if, true):
            updateKeys(frequency)
        case (.oncePerSession, true):
            updateKeys(frequency)
        case (.every, _):
            updateKeys(frequency)
        }
    }

    private func updateKeys(_ frequency: Frequency<T>) {
        switch frequency {
        case .once(let key):
            persistentStorage.set(1, compositeKey(key))
        case .ifTimePassed(let key, _):
            debugPrint("setting: \(dateProvider().timeIntervalSince1970)")
            persistentStorage.set(dateProvider(), compositeKey(key))
        case .if(_): break
        case .oncePerSession(let key):
            sessionStorage.set(1, compositeKey(key))
        case .every(let key, _):
            let times = persistentStorage.getInt(compositeKey(key)) ?? 0
            persistentStorage.set(times + 1, compositeKey(key))
        }
    }

    private func compositeKey(_ key: T) -> String {
        "\(profile).\(key.rawValue)"
    }
}

private extension DispatchTimeInterval {
    func toDouble() -> Double {
        var result: Double = 0

        switch self {
        case .seconds(let value):
            result = Double(value)
        case .milliseconds(let value):
            result = Double(value)*0.001
        case .microseconds(let value):
            result = Double(value)*0.000001
        case .nanoseconds(let value):
            result = Double(value)*0.000000001

        case .never:
            result = 0
        @unknown default:
            fatalError()
        }

        return result
    }
}
