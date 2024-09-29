//
//  UnauthenticatedView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture
import SwiftUI

struct UnauthenticatedView: View {
    let store: StoreOf<UnauthenticatedDomain>

    var body: some View {
        VStack {
            NavigationLink {
            } label: {
                Text("Login")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Login")
    }
}

// MARK: - SwiftUI previews

#Preview {
    let store = Store(initialState: UnauthenticatedDomain.State()) {
        UnauthenticatedDomain()
    }
    
    return NavigationStack {
        UnauthenticatedView(store: store)
    }
}
