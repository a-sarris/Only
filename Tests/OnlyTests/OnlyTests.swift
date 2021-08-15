import XCTest
@testable import Only

enum Key: String, CaseIterable {
    case key
}

class MockStorage: OnlyStorage {

    enum Action: Equatable {
        case setInt(_ value: Int, _ key: String)
        case setDate(_ value: Date, _ key: String)
        case getInt(_ key: String)
        case getDate(_ key: String)
    }

    var actions = [Action]()
    var responses: [Any?] = []

    init(_ responses: [Any?] = []) {
        self.responses = responses
    }


    func set(_ value: Int, _ key: String) {
        actions += [.setInt(value, key)]
    }

    func set(_ date: Date, _ key: String) {
        actions += [.setDate(date, key)]
    }

    func getInt(_ key: String) -> Int? {
        actions += [Action.getInt(key)]
        return responses.removeFirst() as! Int?
    }

    func getDate(_ key: String) -> Date? {
        actions += [Action.getDate(key)]
        return responses.removeFirst() as! Date?
    }

}

class RunOnceTests: XCTestCase {

    var mockStorage: MockStorage!
    var mockSessionStorage: MockStorage!

    override func setUp() {
        mockStorage = MockStorage()
        mockSessionStorage = MockStorage()
    }

    func testRunOncePreference() {
        // Given
        var timesRun = 0
        UserDefaults.standard.removeObject(forKey: "com.execute.only.key")
        mockStorage.responses = [nil, 1]
        // When

        Only(persistentStorage: mockStorage,
             frequency: .once(Key.key)) {
            timesRun += 1
        }

        Only(persistentStorage: mockStorage,
             frequency: .once(Key.key)) {
            timesRun += 1
        }

        // Then

        XCTAssertEqual(timesRun, 1)
    }


    func testRunOnce() throws {
        // Given
        var timesRun = 0
        mockStorage.responses = [nil, 1]
        // When
        
        Only(with: "aris",
             persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .once(Key.key)) {
            timesRun += 1
        }

        Only(with: "aris",
             persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .once(Key.key)) {
            timesRun += 1
        }

        // Then

        XCTAssertEqual(timesRun, 1)
        XCTAssertEqual(mockStorage.actions, [.getInt("aris.key"),
                                             .setInt(1, "aris.key"),
                                             .getInt("aris.key")])
    }


    func testIf() throws {
        // Given
        var timesRun = 0
        // When

        Only<Key>(with: "aris",
                   persistentStorage: mockStorage,
                   sessionStorage: mockSessionStorage,
                   frequency: .`if`({true})) {
            timesRun += 2
        }

        Only<Key>(with: "aris",
                   persistentStorage: mockStorage,
                   sessionStorage: mockSessionStorage,
                   frequency: .`if`({false})) {
            timesRun += 1
        }

        // Then

        XCTAssertEqual(timesRun, 2)
        XCTAssertEqual(mockStorage.actions, [])
    }

    func testIfTimePassedIntervalNow() throws {
        // Given
        var timesRun = 0
        mockStorage.actions = []
        mockStorage.responses = [Date(), Date()]
        // When

        Only<Key>(with: "aris",
                   persistentStorage: mockStorage,
                   sessionStorage: mockSessionStorage,
                   frequency: .ifTimePassed(Key.key, .seconds(1))) {
            timesRun += 1
        }

        // Then

        XCTAssertEqual(timesRun, 0)
    }

    func testIfTimePassedInterval() throws {
        testIfTimePassed(.nanoseconds(1000000000))
        testIfTimePassed(.microseconds(1000000))
        testIfTimePassed(.milliseconds(1000))
        testIfTimePassed(.seconds(1))
    }

    func testIfTimePassed(_ interval: DispatchTimeInterval) {
        // Given
        var timesRun = 0
        let mockDate = Date()
        debugPrint("mockDate: \(mockDate.timeIntervalSince1970)")
        mockStorage.actions = []
        mockStorage.responses = [nil, mockDate, mockDate]
        // When

        Only<Key>(with: "aris",
                   persistentStorage: mockStorage,
                   sessionStorage: mockSessionStorage,
                   frequency: .ifTimePassed(Key.key, interval),
                   currentDateProvider: {mockDate}) {
            timesRun += 1
        }

        let mockDate1 = mockDate.advanced(by: 0.95)

        Only<Key>(with: "aris",
                   persistentStorage: mockStorage,
                   sessionStorage: mockSessionStorage,
                   frequency: .ifTimePassed(Key.key, interval),
                   currentDateProvider: {mockDate1}) {
            timesRun += 1
        }

        let mockDate2 = mockDate.advanced(by: 1.01)

        Only<Key>(with: "aris",
                   persistentStorage: mockStorage,
                   sessionStorage: mockSessionStorage,
                   frequency: .ifTimePassed(Key.key, interval),
                   currentDateProvider: {mockDate2}) {
            timesRun += 1
        }


        // Then

        XCTAssertEqual(timesRun, 2)
        XCTAssertEqual(mockStorage.actions, [.getDate("aris.key"),
                                             .setDate(mockDate, "aris.key"),
                                             .getDate("aris.key"),
                                             .getDate("aris.key"),
                                             .setDate(mockDate2, "aris.key")])
    }

    func testOncePerSession() {
        // Given
        var timesRun = 0
        mockSessionStorage.responses = [nil, 1]
        // When

        Only(persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .oncePerSession(Key.key)) {
            timesRun += 1
        }

        Only(persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .oncePerSession(Key.key)) {
            timesRun += 1
        }

        // Then

        XCTAssertEqual(timesRun, 1)
        XCTAssertEqual(mockStorage.actions, [])
        XCTAssertEqual(mockSessionStorage.actions, [.getInt("com.execute.only.key"),
                                                    .setInt(1, "com.execute.only.key"),
                                                    .getInt("com.execute.only.key")])
    }

    func testEveryXTimes() {
        // Given
        var timesRun = 0
        let every = 4
        mockStorage.responses = [nil, nil, 1, 1, 2, 2, 3, 3, 4, 4]
        // When

        Only(persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .every(Key.key, times: every)) {
            timesRun += 1
        }

        Only(persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .every(Key.key, times: every)) {
            timesRun += 1
        }

        Only(persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .every(Key.key, times: every)) {
            timesRun += 1
        }

        Only(persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .every(Key.key, times: every)) {
            timesRun += 1
        }

        Only(persistentStorage: mockStorage,
             sessionStorage: mockSessionStorage,
             frequency: .every(Key.key, times: every)) {
            timesRun += 1
        }

        // Then

        XCTAssertEqual(timesRun, 2)
        XCTAssertEqual(mockSessionStorage.actions, [])
        XCTAssertEqual(mockStorage.actions, [.getInt("com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .setInt(1, "com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .setInt(2, "com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .setInt(3, "com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .setInt(4, "com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .getInt("com.execute.only.key"),
                                             .setInt(5, "com.execute.only.key"),
        ])
    }
}
