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
    case any([Frequency])
    case all([Frequency])
}



class ExecuteOnly<T: ExecuteOnlyKey> where T.RawValue == String {

    private static var session: ExecuteOnlyModel {
        SessionStorage.session
    }

    @discardableResult
    init(storage: ExecuteOnlyStorage = UserDefaults.standard,
         profile: String = "com.executeOnly",
         _ frequency: Frequency<T>,
         block: () -> ()) {

        //let keys = T.allCases.map{ T.name() + $0.rawValue }
        let storedKeys = storage.get(profile) ?? ExecuteOnlyModel()
        if self.shouldExecute(frequency,
                              storedKeys: storedKeys) {
            block()
            let newModel = updateKeys(frequency,
                       storedKeys: storedKeys,
                       storage: storage)
            storage.set(newModel,
                        forKey: profile)
        }
    }

//    static func reset(storage: ExecuteOnlyStorage = UserDefaults.standard,
//                      profile: String = "com.executeOnly",
//                      key: T) {
//        var storedKeys = storage.dictionary(forKey: profile)
//        storedKeys?[key.rawValue] = nil
//        storage.set(storedKeys, forKey: profile)
//        var session = ExecuteOnly.session
//        session.timeState[key.rawValue] = nil
//        session.valueState[key.rawValue] = nil
//    }

    private func shouldExecute(_ frequency: Frequency<T>,
                               storedKeys: ExecuteOnlyModel) -> Bool {
        switch frequency {
        case .once(let key):
            return storedKeys.timeState[key.rawValue] == nil
        case .if(let control):
            return control()
        case .ifTimePassed(let key, let timeLimit):
            guard let value = storedKeys.timeState[key.rawValue] else { return true }
            return Date(timeIntervalSince1970: value).advanced(by: timeLimit.toDouble() ?? 0) < Date()
        case .oncePerSession(let key):
            return ExecuteOnly.session.timeState[key.rawValue] == nil
        case .every(let key, let times):
            let timesExecuted = storedKeys.valueState[key.rawValue] ?? 0
            return timesExecuted + 1 == times
        case .any(let frequencies):
            return frequencies.lazy.map{ self.shouldExecute($0, storedKeys: storedKeys) }.firstIndex(of: true) != nil
        case .all(let frequencies):
            return frequencies.map { self.shouldExecute($0, storedKeys: storedKeys) }.firstIndex(of: false) == nil
        }
    }

    private func updateKeys(_ frequency: Frequency<T>,
                            storedKeys: ExecuteOnlyModel,
                            storage: ExecuteOnlyStorage) -> ExecuteOnlyModel {
        var mutableStoredKeys = storedKeys
        switch frequency {
        case .once(let key), .ifTimePassed(let key, _):
            mutableStoredKeys.timeState[key.rawValue] = Date().timeIntervalSince1970
        case .if(_): break
        case .oncePerSession(let key):
            var session = SessionStorage.session
            session.timeState[key.rawValue] = Date().timeIntervalSince1970
        case .every(let key, _):
            let times = mutableStoredKeys.valueState[key.rawValue] ?? 0
            mutableStoredKeys.valueState[key.rawValue] = times + 1
        case .all(let frequencies), .any(let frequencies):
            frequencies.forEach{
                let newStorage = updateKeys($0,
                                            storedKeys: storedKeys,
                                            storage: storage)

            }
        }
        return storedKeys
    }
}

private extension DispatchTimeInterval {
    func toDouble() -> Double? {
        var result: Double? = 0

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
            result = nil
        @unknown default:
            fatalError()
        }

        return result
    }
}


//
//  ExecuteOnlyStorage.swift
//  RunOnce
//
//  Created by Sarris, Aris, Vodafone Greece on 05/02/2021.
//  Copyright © 2021 Sarris, Aris, Vodafone Greece. All rights reserved.
//

import Foundation

protocol ExecuteOnlyStorage {
    func set(_ value: Any?, forKey defaultName: String)
    func data(forKey defaultName: String) -> Data?
}

extension ExecuteOnlyStorage {

    func get(_ key: String) -> ExecuteOnlyModel? {
        let data = self.data(forKey: key)
        guard let modelData = data else { return nil }
        let model = try? JSONDecoder().decode(ExecuteOnlyModel.self,
                                              from: modelData)
        return model
    }

    func set(_ value: ExecuteOnlyModel?, forKey defaultName: String) {
        let data = try! JSONEncoder().encode(value)
        set(data, forKey: defaultName)
    }
}

extension UserDefaults: ExecuteOnlyStorage {}

struct ExecuteOnlyModel: Codable {
    var timeState: [String: TimeInterval]
    var valueState: [String: Int]
}

extension ExecuteOnlyModel {
    init() {
        timeState = [String: TimeInterval]()
        valueState = [String: Int]()
    }
}



class SessionStorage {
     static var session = ExecuteOnlyModel()
}
