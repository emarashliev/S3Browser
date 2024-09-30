//
//  AppCoreDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture

@Reducer
struct AppCoreDomain {
    
    @ObservableState
    enum State: Equatable {
        @Shared(.appStorage("logged")) static var logged = false
        @Shared(.appStorage("bucket")) static var bucket = ""

        case loggedIn(AuthenticatedDomain.State)
        case loggedOut(UnauthenticatedDomain.State)
        
        init() {
            if State.logged {
                self = AppCoreDomain.State.loggedIn(.init(bucket: State.bucket))
            } else {
                self = AppCoreDomain.State.loggedOut(.init())
            }
        }
    }

    enum Action {
        case loggedIn(AuthenticatedDomain.Action)
        case loggedOut(UnauthenticatedDomain.Action)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .loggedOut(.successfulLogin(bucket)):
                State.logged = true
                State.bucket = bucket
                state = .loggedIn(.init(bucket: bucket))
                return .none
            case .loggedIn(.successfulLogout):
                State.logged = false
                State.bucket = ""
                state = .loggedOut(.init())
                return .none
            case .loggedIn(_):
                return .none
            case .loggedOut(_):
                return .none
            }
        }
        .ifCaseLet(\.loggedIn, action: \.loggedIn) {
            AuthenticatedDomain()
        }
        .ifCaseLet(\.loggedOut, action: \.loggedOut) {
            UnauthenticatedDomain()
        }._printChanges()
    }
}
