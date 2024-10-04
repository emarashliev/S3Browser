//
//  AuthenticatedDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture

@Reducer
struct AuthenticatedDomain {

    @ObservableState
    struct State: Equatable {
        let bucket: String
        var keys: [String] = []
        @Shared(.inMemory("logout")) var logout = false

    }

    enum Action: Equatable {
        case onAppear
        case logout(Bool)
        case successfulLogout
    }

    @Dependency(\.keychain) var keychain
    @Dependency(\.s3Bucket) var s3Bucket

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .logout(logout):
                if logout {
                    return .send(.successfulLogout)
                }
                return .none
            case .successfulLogout:
                return .run { _ in
                    try await keychain.clear()
                }
            case .onAppear:
                return .publisher({ state.$logout.publisher.map(Action.logout) })
//                    .merge(with: .run { send in
//                        if !s3Bucket.loggedin {
//                            try await s3Bucket.login(
//                                accessKey: keychain.accessKey,
//                                secret: keychain.secret,
//                                region: keychain.region
//                            )
//                        }
//                    })
            }
        }
    }
}
