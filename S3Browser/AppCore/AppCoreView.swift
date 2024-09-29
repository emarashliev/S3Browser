//
//  AppCoreView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture
import SwiftUI

struct AppCoreView: View {
    let store: StoreOf<AppCoreDomain>
    
    var body: some View {
        switch store.state {
        case .loggedIn:
            if let store = store.scope(state: \.loggedIn, action: \.loggedIn) {
                AuthenticatedView(store: store)
            }
        case .loggedOut:
            if let store = store.scope(state: \.loggedOut, action: \.loggedOut) {
                NavigationStack {
                    UnauthenticatedView(store: store)
                }
            }
        }
    }
}
