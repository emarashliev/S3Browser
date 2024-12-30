//
//  DownloadView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 5.10.24.
//
import ComposableArchitecture
import SwiftUI

struct DownloadComponentView: View {
    @State var isVisible = false
    @Bindable var store: StoreOf<DownloadComponentDomain>

    var body: some View {
        VStack {
            if isVisible {
                button.alert($store.scope(state: \.alert, action: \.alert))
            } else {
                button
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private var button: some View {
        Button {
            store.send(.buttonTapped)
        } label: {
            if store.mode == .downloaded {
                Image(systemName: "checkmark.circle")
                    .tint(.accentColor)
            } else if store.mode.isDownloading {
                ZStack {
                    CircularLoadingView()
                        .frame(width: 16, height: 16)
                    Rectangle()
                        .frame(width: 6, height: 6)
                }
            } else if store.mode == .notDownloaded {
                Image(systemName: "icloud.and.arrow.down")
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.primary)
    }
}

#Preview {
    HStack {
        DownloadComponentView(
            store: Store(
                initialState: DownloadComponentDomain.State(
                    id: UUID(),
                    key: "some/test/key",
                    mode: .notDownloaded
                )
            ) {}
        )
        DownloadComponentView(
            store: Store(
                initialState: DownloadComponentDomain.State(
                    id: UUID(),
                    key: "some/test/key",
                    mode: .downloading
                )
            ) {}
        )
        DownloadComponentView(
            store: Store(
                initialState: DownloadComponentDomain.State(
                    id: UUID(),
                    key: "some/test/key",
                    mode: .downloaded
                )
            ) {}
        )
    }
}
