//
//  UnauthenticatedDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture
import OSLog

@Reducer
struct UnauthenticatedDomain {
    
    private let logger = Logger(subsystem: "com.emarashliev.S3Browser", category: "UnauthenticatedDomain")

    // MARK: - State
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        var accessKey = ""
        var secret = ""
        var bucket = ""
        var region = ""
        var isComplete = false
        var isLoading = false
        @Shared(.appStorage("logged")) var loggedin = false
        @Shared(.appStorage("bucket-name")) var bucketName = ""
    }

    // MARK: - Action
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case signInPressed
        case set(region: String)
        case successfulLogin
        case successfulKeychainSave
        case handleError(Error)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    // MARK: - Dependencies
    @Dependency(\.keychain) var keychain
    @Dependency(\.s3Bucket) var s3Bucket

    // MARK: - body
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
                
            case let .handleError(error):
                return handleError(state: &state, error: error)

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Helpers
    private func binding(state: inout State) -> Effect<Self.Action> {
        if !state.bucket.isEmpty && !state.accessKey.isEmpty &&
            !state.secret.isEmpty && !state.region.isEmpty {

            state.isComplete = true
        } else if !state.bucket.isEmpty && !state.accessKey.isEmpty && !state.secret.isEmpty {
            let bucket = state.bucket
            let accessKey = state.accessKey
            let secret = state.secret

            enum CancelID { case debounce }

            return .run { send in
                try await Task.sleep(for: .milliseconds(600))
                let region = try await s3Bucket.getBucketRegion(
                    bucket: bucket,
                    accessKey: accessKey,
                    secret: secret
                )
                await send(.set(region: region))
            }
            .cancellable(id: CancelID.debounce, cancelInFlight: true)
        } else {
            state.isComplete = false
        }
        return .none
    }

    private func signInPressed(state: inout State) -> Effect<Self.Action> {
        state.isLoading = true

        let bucket = state.bucket
        let accessKey = state.accessKey
        let secret = state.secret
        let region = state.region

        return .run { send in
           try await s3Bucket.login(
                bucket: bucket,
                accessKey: accessKey,
                secret: secret,
                region: region
            )

            await send(.successfulLogin)
        } catch: { error, send in
            await send(.handleError(error))
        }
    }

    private func setRegion(state: inout State, region: String) -> Effect<Self.Action> {
        state.region = region
        if !state.bucket.isEmpty && !state.accessKey.isEmpty &&
            !state.secret.isEmpty && !state.region.isEmpty {
            
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
            await send(.successfulKeychainSave, animation: .easeInOut)
        }
    }

    private func successfulKeychainSave(state: inout State) -> Effect<Self.Action> {
        state.$bucketName.withLock { $0 = state.bucket }
        state.$loggedin.withLock { $0 = true }
        state.isLoading = false
        return .none
    }
    
    private func handleError(state: inout State, error: Error) -> Effect<Self.Action> {
        state.isLoading = false
        state.alert =  AlertState {
            TextState(error.localizedDescription)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        }
        logger.error("Operation failed with error: \(String(describing: error))")
        return .none
    }
}
