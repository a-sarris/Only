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
