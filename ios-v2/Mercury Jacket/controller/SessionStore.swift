import Foundation

// MARK: - Protocol

protocol SessionStore {
    func allSessions() -> [Session]
    func persist(session: Session)
}

// MARK: - UserDefaults Implementation

final class UserDefaultsSessionStore: SessionStore {

    private let defaults: UserDefaults
    private let storageKey: String
    private let maxSessions: Int

    init(defaults: UserDefaults = .standard,
         storageKey: String = "mj_session_history_v1",
         maxSessions: Int = 30) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maxSessions = maxSessions
    }

    func allSessions() -> [Session] {
        guard let data = defaults.data(forKey: storageKey),
              let sessions = try? JSONDecoder().decode([Session].self, from: data) else {
            return []
        }
        return sessions
    }

    func persist(session: Session) {
        var all = allSessions()
        all.insert(session, at: 0)
        all = Array(all.prefix(maxSessions))
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
