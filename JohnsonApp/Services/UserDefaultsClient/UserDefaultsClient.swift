//
//  UserDefaultsClient.swift
//  JohnsonApp
//

import ComposableArchitecture
import Dependencies
import Foundation


private let activeSessionIdKey = "activeSessionId"

struct UserDefaultsClient: Sendable {
    var activeSessionId:    @Sendable () -> UUID?
    var setActiveSessionId: @Sendable (UUID?) -> Void
}


extension UserDefaultsClient: DependencyKey {

    static var liveValue: Self {
        Self(
            activeSessionId: {
                guard let raw = UserDefaults.standard.string(forKey: activeSessionIdKey) else {
                    return nil
                }
                return UUID(uuidString: raw)
            },
            setActiveSessionId: { id in
                if let id {
                    UserDefaults.standard.set(id.uuidString, forKey: activeSessionIdKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: activeSessionIdKey)
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
