import XCTest
@testable import Mercury_Jacket

final class JacketStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: UserDefaultsJacketStore!

    override func setUp() {
        super.setUp()
        suiteName = "test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = UserDefaultsJacketStore(
            defaults: defaults,
            jacketsKey: "test_jackets",
            currentJacketKey: "test_current"
        )
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Add / Remove

    func testAddAndRetrieveJacket() {
        let jacket = Jacket(id: "A", name: "Alpha")
        store.addJacket(jacket)

        let all = store.allJackets()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, "A")
        XCTAssertEqual(all.first?.name, "Alpha")
    }

    func testRemoveJacket() {
        let jacket = Jacket(id: "A", name: "Alpha")
        store.addJacket(jacket)
        store.removeJacket(jacket)

        XCTAssertTrue(store.allJackets().isEmpty)
    }

    func testRemoveCurrentJacketClearsCurrent() {
        let jacket = Jacket(id: "A", name: "Alpha")
        store.addJacket(jacket)
        store.setCurrentJacket(jacket)
        XCTAssertNotNil(store.currentJacket)

        store.removeJacket(jacket)
        XCTAssertNil(store.currentJacket)
    }

    // MARK: - Current jacket

    func testSetAndGetCurrentJacket() {
        let jacket = Jacket(id: "B", name: "Beta")
        store.addJacket(jacket)
        store.setCurrentJacket(jacket)

        XCTAssertEqual(store.currentJacket?.id, "B")
        XCTAssertTrue(store.hasCurrentJacket())
    }

    func testClearCurrentJacket() {
        let jacket = Jacket(id: "B", name: "Beta")
        store.addJacket(jacket)
        store.setCurrentJacket(jacket)
        store.setCurrentJacket(nil)

        XCTAssertNil(store.currentJacket)
        XCTAssertFalse(store.hasCurrentJacket())
    }

    // MARK: - hasAnyJackets

    func testHasAnyJacketsWhenEmpty() {
        XCTAssertFalse(store.hasAnyJackets())
    }

    func testHasAnyJacketsAfterAdd() {
        store.addJacket(Jacket(id: "1", name: "J"))
        XCTAssertTrue(store.hasAnyJackets())
    }

    // MARK: - Multiple jackets sorted

    func testMultipleJacketsSortedByIdDescending() {
        store.addJacket(Jacket(id: "A", name: "A"))
        store.addJacket(Jacket(id: "C", name: "C"))
        store.addJacket(Jacket(id: "B", name: "B"))

        let ids = store.allJackets().map(\.id)
        XCTAssertEqual(ids, ["C", "B", "A"])
    }

    // MARK: - Update preserves current

    func testUpdateCurrentJacketOnAdd() {
        let jacket = Jacket(id: "X", name: "Original")
        store.addJacket(jacket)
        store.setCurrentJacket(jacket)

        let updated = Jacket(id: "X", name: "Updated")
        store.addJacket(updated)

        XCTAssertEqual(store.currentJacket?.name, "Updated")
    }
}
