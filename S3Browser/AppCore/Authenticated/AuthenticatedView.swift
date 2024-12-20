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
            let store = Store(initialState: FileBrowserDomain.State(name: store.bucketName, isFile: false)) {
                FileBrowserDomain()
            }
            FileBrowserView(store: store)
        }
        .tint(LinearGradient.appColor)
        .onAppear { store.send(.onAppear) }
    }
}
