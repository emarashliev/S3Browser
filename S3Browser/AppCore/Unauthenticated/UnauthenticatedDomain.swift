//
//  UnauthenticatedDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture

@Reducer
struct UnauthenticatedDomain {
    
    @ObservableState
    struct State: Equatable {
        var accessKey = ""
        var secret = ""
        var bucket = ""
        var isComplete = false
    }
    
    enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case signInPressed
        case getLogin(region: String)
        case successfulLogin(bucket: String)
    }
    
    @Dependency(\.keychain) var keychain
    @Dependency(\.s3Bucket) var s3Bucket

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                if state.bucket.count > 2 && state.accessKey.count > 2  && state.secret.count > 2 {
                    state.isComplete = true
                } else {
                    state.isComplete = false
                }
                return .none
            case .signInPressed:
                let bucket = state.bucket
                let accessKey = state.accessKey
                let secret = state.secret

                return .run { send in
                    do {
                        try await keychain.set(value: accessKey, key: .accessKey)
                        try await keychain.set(value: secret, key: .secret)
                        let region = try await s3Bucket.getBucketRegion(
                            bucket: bucket,
                            accessKey: accessKey,
                            secret: secret
                        )
                        try await keychain.set(value: region, key: .region)
                        await send(.getLogin(region: region))
                    } catch {
                        try await keychain.clear()
                        throw error
                    }
                }
            case let .getLogin(region):
                let bucket = state.bucket
                let accessKey = state.accessKey
                let secret = state.secret

                return .run { send in
                    try await s3Bucket.login(
                        accessKey: accessKey,
                        secret: secret,
                        region: region
                    )
                    await send(.successfulLogin(bucket: bucket))
                }
            case .successfulLogin:
                return .none
            }
        }
    }
}
