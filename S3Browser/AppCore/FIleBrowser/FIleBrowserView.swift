//
//  FIleBrowserView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 4.10.24.
//

import ComposableArchitecture
import SwiftUI

struct FIleBrowserView: View {
    @Bindable var store: StoreOf<FIleBrowserDomain>

    var body: some View {
        List(store.scope(state: \.rows, action: \.rows)) { rowStore in
            @Bindable var rowStore = rowStore
            if rowStore.isFile {
                HStack {
                    Text(rowStore.name)
                }
            } else {
                NavigationLink {
                    FIleBrowserView(store: rowStore)
                } label: {
                    HStack {
                        Text(rowStore.name)

                    }
                }
            }
        }
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.logoutPressed)
                } label: {
                    Text("Logout")
                }
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
