import Foundation

// MARK: - Protocol

protocol JacketStore {
    var currentJacket: Jacket? { get }
    func setCurrentJacket(_ jacket: Jacket?)
    func addJacket(_ jacket: Jacket)
    func removeJacket(_ jacket: Jacket)
    func allJackets() -> [Jacket]
    func hasCurrentJacket() -> Bool
    func hasAnyJackets() -> Bool
}

// MARK: - UserDefaults Implementation

final class UserDefaultsJacketStore: JacketStore {

    private let defaults: UserDefaults
    private let jacketsKey: String
    private let currentJacketKey: String

    private(set) var currentJacket: Jacket?

    init(defaults: UserDefaults = .standard,
         jacketsKey: String = "jackets",
         currentJacketKey: String = "current_jacket") {
        self.defaults = defaults
        self.jacketsKey = jacketsKey
        self.currentJacketKey = currentJacketKey
        self.currentJacket = loadCurrentJacket()
    }

    func setCurrentJacket(_ jacket: Jacket?) {
        currentJacket = jacket
        if let jacket = jacket {
            defaults.set(jacket.id, forKey: currentJacketKey)
        } else {
            defaults.removeObject(forKey: currentJacketKey)
        }
    }

    func addJacket(_ jacket: Jacket) {
        var jackets = rawJackets()
        guard let encoded = try? JSONEncoder().encode(jacket),
              let jsonString = String(data: encoded, encoding: .utf8) else { return }
        jackets[jacket.id] = jsonString
        defaults.set(jackets, forKey: jacketsKey)

        if currentJacket?.id == jacket.id {
            setCurrentJacket(jacket)
        }
    }

    func removeJacket(_ jacket: Jacket) {
        var jackets = rawJackets()
        jackets.removeValue(forKey: jacket.id)
        defaults.set(jackets, forKey: jacketsKey)

        if currentJacket?.id == jacket.id {
            setCurrentJacket(nil)
        }
    }

    func allJackets() -> [Jacket] {
        let sorted = rawJackets().sorted { $0.key > $1.key }
        return sorted.compactMap { _, json in
            guard let data = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(Jacket.self, from: data)
        }
    }

    func hasCurrentJacket() -> Bool {
        defaults.string(forKey: currentJacketKey) != nil
    }

    func hasAnyJackets() -> Bool {
        let jackets = defaults.dictionary(forKey: jacketsKey) as? [String: String]
        return (jackets?.count ?? 0) > 0
    }

    // MARK: - Private

    private func rawJackets() -> [String: String] {
        defaults.dictionary(forKey: jacketsKey) as? [String: String] ?? [:]
    }

    private func loadCurrentJacket() -> Jacket? {
        guard let id = defaults.string(forKey: currentJacketKey) else { return nil }
        let jackets = rawJackets()
        guard let json = jackets[id],
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Jacket.self, from: data)
    }
}
