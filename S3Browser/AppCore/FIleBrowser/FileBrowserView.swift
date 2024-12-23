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
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                ProgressView()
                    .navigationTitle(store.name)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack {
                                Button {
                                } label: {
                                    Button {
                                        store.send(.reorderRows, animation: .default)
                                    } label: {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .foregroundStyle(LinearGradient.appColor)
                                    }
                                    
                                }
                                
                                Button {
                                    store.send(.logoutPressed)
                                } label: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundStyle(LinearGradient.appColor)
                                }
                                .alert($store.scope(state: \.alert, action: \.alert))
                            }
                        }
                    }
                    .onAppear { store.send(.onAppear) }
            }
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
                    HStack {
                        Button {
                            store.send(.reorderRows, animation: .default)
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundStyle(LinearGradient.appColor)
                        }
                        
                        Button {
                            store.send(.logoutPressed)
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(LinearGradient.appColor)
                        }
                        .alert($store.scope(state: \.alert, action: \.alert))
                    }
                }
            }
        }
    }
}

#Preview {
    let rows = [
        FileBrowserDomain.State(name: "Folder 1", isFile: false),
        FileBrowserDomain.State(name: "File 1", isFile: true)
    ]
    let state = FileBrowserDomain.State(
        name: "Bucket name",
        isFile: false,
        rows: IdentifiedArrayOf(uniqueElements: rows)
    )
    let store = Store(initialState: state) {
        FileBrowserDomain()
    }
    FileBrowserView(store: store)
}
