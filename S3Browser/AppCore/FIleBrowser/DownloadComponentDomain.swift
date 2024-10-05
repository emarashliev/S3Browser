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

        enum Alert {
            case deleteButtonTapped
            case stopButtonTapped
        }
    }

    @Dependency(\.s3Bucket) var s3Bucket

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.deleteButtonTapped)):
                state.mode = .notDownloaded
                return .none

            case .alert(.presented(.stopButtonTapped)):
                state.mode = .notDownloaded
                return .cancel(id: state.id)

            case .alert:
                return .none

            case .buttonTapped:
                return buttonTapped(state: &state)

            case .download(.success):
                state.mode = .downloaded
                state.alert = nil
                return .none

            case let .download(.failure(error)):
                state.mode = .notDownloaded
                state.alert = errorAlert
                return .run { _ in
                    throw error
                }
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private var stopAlert: AlertState<Action.Alert> {
        AlertState {
            TextState("Do you want to stop downloading?")
        } actions: {
            ButtonState(role: .destructive, action: .send(.stopButtonTapped, animation: .default)) {
                TextState("Stop")
            }
            ButtonState(role: .cancel) {
                TextState("No")
            }
        }
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
            state.alert = stopAlert
            return .none

        case .notDownloaded:
            state.mode = .startingToDownload

            let bucket = state.bucketName
            let key = state.key
            return .run { send in
                try await s3Bucket.downloadFile(bucket: bucket, key: key)
                await send(.download(.success(Void())), animation: .default)
            } catch: { error, send in
                await send(.download(.failure(error)), animation: .default)
            }
                .cancellable(id: state.id)

        case .startingToDownload:
            state.alert = stopAlert
            return .none
        }
    }
}

enum Mode: Equatable {
    case downloaded
    case downloading
    case notDownloaded
    case startingToDownload

    var isDownloading: Bool {
        switch self {
        case .downloaded, .notDownloaded:
            return false
        case .downloading, .startingToDownload:
            return true
        }
    }
}
