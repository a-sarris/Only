//
//  RunOnceTests.swift
//  RunOnceTests
//
//  Created by Sarris, Aris, Vodafone Greece on 20/01/2021.
//  Copyright © 2021 Sarris, Aris, Vodafone Greece. All rights reserved.
//

import XCTest
@testable import RunOnce

class MockStorage: ExecuteOnlyStorage {

    enum Action: Equatable {
        case data(String)
        case set(String)
    }

    var actions = [Action]()

    func set(_ value: Any?, forKey defaultName: String) {
        actions += [.set(defaultName)]
    }

    var mockData: Data?
    func data(forKey defaultName: String) -> Data? {
        actions += [.data(defaultName)]
        return mockData
    }
}

class RunOnceTests: XCTestCase {

    var mockStorage: MockStorage!

    override func setUp() {
        mockStorage = MockStorage()
    }

    func testRunOnceFirstTime() throws {
        // Given
        var timesRun = 0

        // When

        ExecuteOnly(storage: mockStorage, .once(Keys.key)) {
            timesRun += 1
        }

        // Then

        XCTAssertEqual(timesRun, 1)
        XCTAssertEqual(mockStorage.actions, [.data("com.executeOnly"),
                                             .set("com.executeOnly")])
    }

    func testRunOnceAlreadyRunOnce() throws {
        // Given
        let model = ExecuteOnlyModel(timeState: [Keys.key.rawValue : 1],
                                     valueState: [String : Int]())
        mockStorage.mockData = try! JSONEncoder().encode(model)
        // When

        ExecuteOnly(storage: mockStorage, .once(Keys.key)) {
            XCTFail()
        }

        // Then

        XCTAssertEqual(mockStorage.actions, [.data("com.executeOnly")])
    }
}
