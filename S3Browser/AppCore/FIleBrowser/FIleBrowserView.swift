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
            if rowStore.isFile {
                HStack {
                    Image(systemName: "document.fill")
                        .foregroundStyle(LinearGradient.appColor)
                    Text(rowStore.name)
                        .fontWeight(.medium)
                    Spacer()
                    DownloadComponentView(
                        store: rowStore.scope(state: \.downloadComponent, action: \.downloadComponent)
                    )
                }
            } else {
                NavigationLink {
                    FIleBrowserView(store: rowStore)
                } label: {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(LinearGradient.appColor)
                    Text(rowStore.name)
                        .fontWeight(.medium)
                }
            }
        }
        .navigationTitle(store.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.logoutPressed)
                } label: {
                    Image(systemName: "person.crop.circle.fill")                        .foregroundStyle(LinearGradient.appColor)
                }
                .alert($store.scope(state: \.alert, action: \.alert))
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
