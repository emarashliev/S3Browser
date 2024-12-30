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
                InputView(data: $store.bucket, title: "Bucket", type: .nonSecure)
                InputView(data: $store.accessKey, title: "Access key", type: .nonSecure)
                InputView(data: $store.secret, title: "Secret", type: .secure)
                InputView(data: $store.region, title: "Region", type: .nonSecure)
            }
            .padding(.bottom, 16)

            Button {
                store.send(.signInPressed)
            } label: {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(LinearGradient.appColor.opacity(0.5))
                        .cornerRadius(40)

                } else {
                    Text("Sign In")
                        .fontWeight(.heavy)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            LinearGradient
                                .appColor
                                .opacity(store.isComplete ? 1.0 : 0.3)
                        )
                        .cornerRadius(40)
                }
            }
            .disabled(!store.isComplete && !store.isLoading)
        }
        .padding()
        .alert($store.scope(state: \.alert, action: \.alert))
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
