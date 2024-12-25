//
//  AuthenticatedDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture

@Reducer
struct AuthenticatedDomain {

    // MARK: - State
    @ObservableState
    struct State: Equatable {
        @Shared(.appStorage("logged")) var loggedin = false
        @Shared(.appStorage("bucket-name")) var bucketName = ""
    }

    // MARK: - Action
    enum Action {
        case onAppear
        case loggedin(Bool)
        case successfulLogout
        case successfulKeychainClear
    }

    // MARK: - Dependencies
    @Dependency(\.keychain) var keychain
    @Dependency(\.s3Bucket) var s3Bucket

    // MARK: - body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .loggedin(loggedin):
                if !loggedin {
                    return .send(.successfulLogout)
                }
                return .none

            case .successfulLogout:
                return .run { send in
                    try await keychain.clear()
                    await send(.successfulKeychainClear, animation: .easeInOut)
                }
                
            case .successfulKeychainClear:
                state.$bucketName.withLock { $0 = "" }
                return .none

            case .onAppear:
                return .publisher { state.$loggedin.publisher.map(Action.loggedin) }
            }
        }
    }
}
