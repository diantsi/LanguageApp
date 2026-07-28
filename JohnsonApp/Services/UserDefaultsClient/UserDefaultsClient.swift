//
//  UserDefaultsClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Dependencies
import Foundation


private enum Keys {
    nonisolated static let activeSessionId = "activeSessionId"
}

struct UserDefaultsClient: Sendable {
    var activeSessionId:    @Sendable () -> UUID?
    var setActiveSessionId: @Sendable (UUID?) -> Void
}


extension UserDefaultsClient: DependencyKey {

    static var liveValue: Self {
        Self(
            activeSessionId: {
                guard let raw = UserDefaults.standard.string(forKey: Keys.activeSessionId) else {
                    return nil
                }
                return UUID(uuidString: raw)
            },
            setActiveSessionId: { id in
                if let id {
                    UserDefaults.standard.set(id.uuidString, forKey: Keys.activeSessionId)
                } else {
                    UserDefaults.standard.removeObject(forKey: Keys.activeSessionId)
                }
            }
        )
    }

    static let testValue = Self(
        activeSessionId:    { nil },
        setActiveSessionId: { _ in }
    )
}


extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
