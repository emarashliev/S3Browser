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
        var region = ""
        var isComplete = false
    }
    
    enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case signInPressed
        case set(region: String)
        case successfulLogin(bucket: String)
    }
    
    @Dependency(\.keychain) var keychain
    @Dependency(\.s3Bucket) var s3Bucket

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                if
                    state.bucket.count > 4 &&
                    state.accessKey.count > 16  &&
                    state.secret.count > 36 &&
                    state.region.count > 4

                {
                    state.isComplete = true
                } else if
                    state.bucket.count > 4 &&
                    state.accessKey.count > 16  &&
                    state.secret.count > 36
                {
                    let bucket = state.bucket
                    let accessKey = state.accessKey
                    let secret = state.secret

                    return .run { send in
                        let region = try await s3Bucket.getBucketRegion(
                            bucket: bucket,
                            accessKey: accessKey,
                            secret: secret
                        )
                        await send(.set(region: region))
                    }
                } else {
                    state.isComplete = false
                }
                return .none
            case .signInPressed:
                let bucket = state.bucket
                let accessKey = state.accessKey
                let secret = state.secret
                let region = state.region

                return .run { send in
                    try await s3Bucket.login(
                        accessKey: accessKey,
                        secret: secret,
                        region: region
                    )
                    await send(.successfulLogin(bucket: bucket))
                }
            case let .set(region):
                state.region = region
                return .none
            case .successfulLogin:
                let accessKey = state.accessKey
                let secret = state.secret
                let region = state.region

                return .run { _ in
                    try await keychain.set(value: accessKey, key: .accessKey)
                    try await keychain.set(value: secret, key: .secret)
                    try await keychain.set(value: region, key: .region)
                }
            }
        }
    }
}
