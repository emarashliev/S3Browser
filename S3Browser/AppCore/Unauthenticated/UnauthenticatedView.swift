//
//  UnauthenticatedView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture
import SwiftUI

struct UnauthenticatedView: View {
    @Bindable var store: StoreOf<UnauthenticatedDomain>
    
    var body: some View {
        VStack {
            Text("S3 Browser")
                .font(.largeTitle)
                .fontWeight(.black)
                .padding(.bottom, 42)
            
            VStack(spacing: 16) {
                InputView(data: $store.bucket, title: "Bucket")
                InputView(data: $store.accessKey, title: "Access key")
                InputView(data: $store.secret, title: "Secret")
            }
            .padding(.bottom, 16)
            
            Button {
                store.send(.signInPressed(bucket: store.bucket, accessKey: store.accessKey, secret: store.secret))
            } label: {
                Text("Sign In")
                    .fontWeight(.heavy)
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(store.isComplete ? 1.0 : 0.3)
                    )
                    .cornerRadius(40)
            }
            .disabled(!store.isComplete)
        }
        .padding()
    }
}

#Preview {
    let store = Store(initialState: UnauthenticatedDomain.State()) {
        UnauthenticatedDomain()
    }
    
    return NavigationStack {
        UnauthenticatedView(store: store)
    }
}
