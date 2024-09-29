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
        case signInPressed(bucket: String, accessKey: String, secret: String)
        case successfulLogin
    }
    
    @Dependency(\.keychain) var keychain
    
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
            case let .signInPressed(bucket, accessKey, secret):
                return .run { _ in
                    try await keychain.set(value: accessKey, key: .accessKey)
                    try await keychain.set(value: secret, key: .secret)
                    try await keychain.set(value: bucket, key: .bucket)
                }
            case .successfulLogin:
                return .none
            }
        }
    }
}
