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
        @Shared(.appStorage("logged")) var loggedin = false
        @Shared(.appStorage("bucket-name")) var bucketName = ""
    }
    
    enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case signInPressed
        case set(region: String)
        case successfulLogin
        case successfulKeychainSave
    }
    
    @Dependency(\.keychain) var keychain
    @Dependency(\.s3Bucket) var s3Bucket

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in

            switch action {
            case .binding:
                return binding(state: &state)

            case .signInPressed:
                return signInPressed(state: &state)

            case let .set(region):
                return setRegion(state: &state, region: region)

            case .successfulLogin:
                return successfulLogin(state: &state)

            case .successfulKeychainSave:
                return successfulKeychainSave(state: &state)
            }
        }
    }

    private func binding(state: inout State) -> Effect<Self.Action> {
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
    }

    private func signInPressed(state: inout State) -> Effect<Self.Action> {
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
            await send(.successfulLogin)
        }
    }

    private func setRegion(state: inout State, region: String) -> Effect<Self.Action> {
        state.region = region
        if
            state.bucket.count > 4 &&
            state.accessKey.count > 16  &&
            state.secret.count > 36 &&
            state.region.count > 4

        {
            state.isComplete = true
        }
        return .none
    }

    private func successfulLogin(state: inout State) -> Effect<Self.Action> {
        let accessKey = state.accessKey
        let secret = state.secret
        let region = state.region

        return .run { send in
            try await keychain.set(value: accessKey, key: .accessKey)
            try await keychain.set(value: secret, key: .secret)
            try await keychain.set(value: region, key: .region)
            await send(.successfulKeychainSave)
        }
    }

    private func successfulKeychainSave(state: inout State) -> Effect<Self.Action> {
        state.bucketName = state.bucket
        state.loggedin = true
        return .none
    }
}
