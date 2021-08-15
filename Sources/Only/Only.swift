//
//  Only.swift
//  RunOnce
//
//  Created by Sarris, Aris on 05/02/2021.
//  Copyright © 2021 Sarris, Aris. All rights reserved.
//

import Foundation

public  let OnlyDefaultProfile: String = "com.execute.only"
public class Only<T: OnlyKey> where T.RawValue == String {

    private var persistentStorage: OnlyStorage
    private var sessionStorage: OnlyStorage
    private let dateProvider: () -> Date
    private let profile: String

    @discardableResult
    public convenience init(_ frequency: OnlyFrequency<T>,
                     _ block: ()->()) {

        self.init(with: OnlyDefaultProfile, frequency: frequency, block: block)
    }

    @discardableResult
    public convenience init(_ profile: String = OnlyDefaultProfile,
                     _ frequency: OnlyFrequency<T>,
                     _ block: ()->()) {

        self.init(with: profile, frequency: frequency, block: block)
    }

    @discardableResult
    public required init(with profile: String = OnlyDefaultProfile,
         persistentStorage: OnlyStorage = UserDefaults.standard,
         sessionStorage: OnlyStorage = OnlySessionStorage(),
         frequency: OnlyFrequency<T>,
         currentDateProvider: @escaping () -> Date = { Date() },
         block: () -> ()) {
        self.dateProvider = currentDateProvider
        self.persistentStorage = persistentStorage
        self.sessionStorage = sessionStorage
        self.profile = profile
        var didRun = false
        if self.shouldExecute(frequency) {
            block()
            didRun = true
        }
        updateKeysIfNeeded(frequency, didExecute: didRun)
    }

    private func shouldExecute(_ frequency: OnlyFrequency<T>) -> Bool {
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

    private func updateKeysIfNeeded (_ frequency: OnlyFrequency<T>, didExecute: Bool) {
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

    private func updateKeys(_ frequency: OnlyFrequency<T>) {
        switch frequency {
        case .once(let key):
            persistentStorage.set(1, compositeKey(key))
        case .ifTimePassed(let key, _):
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
