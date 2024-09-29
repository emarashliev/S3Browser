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
        case loggedIn(AuthenticatedDomain.State)
        case loggedOut(UnauthenticatedDomain.State)
        
        init(authenticated: Bool) {
            if authenticated {
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
        Reduce { _, _ in
            return .none
        }
        .ifCaseLet(\.loggedIn, action: \.loggedIn) {
            AuthenticatedDomain()
        }
        .ifCaseLet(\.loggedOut, action: \.loggedOut) {
            UnauthenticatedDomain()
        }
    }
}
