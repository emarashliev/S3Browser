//
//  AuthenticatedView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture
import SwiftUI

struct AuthenticatedView: View {
    let store: StoreOf<AuthenticatedDomain>
    
    var body: some View {
        NavigationStack {
            let store = Store(initialState: FIleBrowserDomain.State(name: store.bucket, isFile: false)) {
                FIleBrowserDomain()
            }
            FIleBrowserView(store: store)
        }
        .onAppear { store.send(.onAppear) }
    }
}
