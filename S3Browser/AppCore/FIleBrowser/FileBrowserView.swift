//
//  FIleBrowserView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 4.10.24.
//

import ComposableArchitecture
import SwiftUI

struct FileBrowserView: View {
    @Bindable var store: StoreOf<FileBrowserDomain>
    
    var body: some View {
        if store.rows.isEmpty && !store.isRowsFetched {
            ProgressView()
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
        } else {
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
                        FileBrowserView(store: rowStore)
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
        }
    }
}
