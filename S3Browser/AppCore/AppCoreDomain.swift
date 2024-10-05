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
        @Shared(.appStorage("logged")) static var loggedin = false

        case loggedIn(AuthenticatedDomain.State)
        case loggedOut(UnauthenticatedDomain.State)

        init() {
            if State.loggedin {
                self = AppCoreDomain.State.loggedIn(.init())
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
            case .loggedOut(.successfulKeychainSave):
                state = .loggedIn(.init())
                return .none

            case .loggedIn(.successfulKeychainClear):
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
