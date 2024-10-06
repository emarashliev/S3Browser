//
//  DownloadComponentDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 5.10.24.
//

import ComposableArchitecture
import Foundation

@Reducer
struct DownloadComponentDomain {

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        let id: UUID
        let key: String
        var mode: Mode = .notDownloaded
        @Shared(.appStorage("bucket-name")) var bucketName = ""
    }

    enum Action {
        case alert(PresentationAction<Alert>)
        case buttonTapped
        case download(Result<Void, Error>)
        case stopDownloaing

        enum Alert: Equatable {}
    }

    @Dependency(\.s3Bucket) var s3Bucket

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .stopDownloaing:
                state.mode = .notDownloaded
                return .cancel(id: state.id)

            case .buttonTapped:
                return buttonTapped(state: &state)

            case .download(.success):
                state.mode = .downloaded
                return .none

            case let .download(.failure(error)):
                state.mode = .notDownloaded
                state.alert = errorAlert
                return .run { _ in
                    throw error
                }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private var errorAlert: AlertState<Action.Alert> {
        AlertState {
            TextState("Something went wrong")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        }
    }

    private func buttonTapped(state: inout State) -> Effect<Self.Action> {
        switch state.mode {
        case .downloaded:
            return .none

        case .downloading:
            return .send(.stopDownloaing, animation: .default)

        case .notDownloaded:
            state.mode = .downloading

            let bucket = state.bucketName
            let key = state.key
            return .run { send in
                try await s3Bucket.downloadFile(bucket: bucket, key: key)
                await send(.download(.success(Void())), animation: .default)
            } catch: { error, send in
                await send(.download(.failure(error)), animation: .default)
            }
                .cancellable(id: state.id)
        }
    }
}

enum Mode: Equatable {
    case downloaded
    case downloading
    case notDownloaded

    var isDownloading: Bool {
        switch self {
        case .downloaded, .notDownloaded:
            return false
        case .downloading:
            return true
        }
    }
}
