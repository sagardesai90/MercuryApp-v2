import XCTest
@testable import Mercury_Jacket

final class SessionStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: UserDefaultsSessionStore!

    override func setUp() {
        super.setUp()
        suiteName = "test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = UserDefaultsSessionStore(
            defaults: defaults,
            storageKey: "test_sessions",
            maxSessions: 5
        )
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeSession(id: String = UUID().uuidString) -> Session {
        Session(
            id: id,
            jacketName: "Test",
            startDate: Date(),
            endDate: Date(),
            dataPoints: [
                SessionDataPoint(
                    timestamp: Date(),
                    jacketTempCelsius: 22,
                    ambientTempCelsius: 10,
                    powerLevel: 5000,
                    powerOutputRaw: nil,
                    activityLevel: 0,
                    mode: 2
                )
            ]
        )
    }

    func testEmptyByDefault() {
        XCTAssertTrue(store.allSessions().isEmpty)
    }

    func testPersistAndRetrieve() {
        let session = makeSession(id: "S1")
        store.persist(session: session)

        let all = store.allSessions()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, "S1")
    }

    func testNewestFirst() {
        store.persist(session: makeSession(id: "old"))
        store.persist(session: makeSession(id: "new"))

        let ids = store.allSessions().map(\.id)
        XCTAssertEqual(ids.first, "new")
        XCTAssertEqual(ids.last, "old")
    }

    func testMaxSessionsCap() {
        for i in 0..<8 {
            store.persist(session: makeSession(id: "S\(i)"))
        }

        let all = store.allSessions()
        XCTAssertEqual(all.count, 5)
        XCTAssertEqual(all.first?.id, "S7")
    }

    func testPersistPreservesDataPoints() {
        let session = makeSession()
        store.persist(session: session)

        let retrieved = store.allSessions().first!
        XCTAssertEqual(retrieved.dataPoints.count, 1)
        XCTAssertEqual(retrieved.dataPoints.first?.powerLevel, 5000)
    }
}
