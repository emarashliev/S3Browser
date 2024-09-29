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
        
    }
    
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
            case .signInPressed :
                return .none
            }
        }._printChanges()
    }
}
