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
        Text("AuthenticatedView")
        Button {
            store.send(.successfulLogout)
        } label: {
            Text("Logout")
        }
    }
}

//#Preview {
//    UnauthenticatedView()
//}

