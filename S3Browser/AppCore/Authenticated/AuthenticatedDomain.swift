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
    struct State: Equatable {}
    
    enum Action: Equatable {
        case successfulLogout
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .successfulLogout:
                return .none
            }
        }
    }
}
