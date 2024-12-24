//
//  FileBrowserDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 4.10.24.
//

import ComposableArchitecture
import Foundation

@Reducer
struct FileBrowserDomain {

    @ObservableState
    struct State: Equatable, Identifiable {
        @Presents var alert: AlertState<Action.Alert>?
        let id: UUID
        var name: String
        let isFile: Bool
        var path: String
        var downloadComponent: DownloadComponentDomain.State
        var isRowsFetched = false
        var order: SortOrder = .forward
        var rows: IdentifiedArrayOf<Self> = []
        @Shared(.appStorage("logged")) var loggedin = false
        @Shared(.appStorage("bucket-name")) var bucketName = ""

        init(
            id: UUID? = nil,
            name: String,
            isFile: Bool,
            path: String = "" ,
            existsLocally: Bool = false,
            rows: IdentifiedArrayOf<State> = []
        ) {
            @Dependency(\.uuid) var uuid
            self.id = id ?? uuid()
            self.name = name
            self.rows = rows
            self.isFile = isFile
            self.path = path
            self.downloadComponent = .init(
                id: self.id,
                key: path,
                mode: existsLocally ? .downloaded : .notDownloaded
            )
        }
    }

    enum Action {
        case onAppear
        case loginS3
        case loginS3Response(TaskResult<Void>)
        case fetchObjects
        case fetchResponse(TaskResult<[S3BucketObject]>)
        case set(IdentifiedArrayOf<State>)
        indirect case rows(IdentifiedActionOf<FileBrowserDomain>)
        case logoutPressed
        case reorderRows
        case downloadComponent(DownloadComponentDomain.Action)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {
            case logout
        }
    }

    @Dependency(\.s3Bucket) var s3Bucket
    @Dependency(\.keychain) var keychain

    var body: some ReducerOf<Self> {
        Scope(state: \.downloadComponent, action: \.downloadComponent) {
            DownloadComponentDomain()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.loggedin {
                    return .run { await $0(.loginS3) }
                } else {
                    return .none
                }

            case .loginS3:
                return loginIntoS3(state: state)

            case .loginS3Response(.success):
                return .run { send in
                    await send(.fetchObjects)
                }

            case let .loginS3Response(.failure(error)):
                state.alert = errorAlert
                return .run { _ in
                    throw error
                }

            case .fetchObjects:
                return fetchObjects(state: state)

            case let .fetchResponse(.success(objects)):
                return transformObjectsToRows(state: state, objects: objects)

            case let .fetchResponse(.failure(error)):
                state.alert = errorAlert
                return .run { _ in
                    throw error
                }

            case .reorderRows:
                state.order = state.order == .forward ? .reverse : .forward
                state.rows.sort(using: SortDescriptor(\.name, order: state.order))
                return .none

            case let .set(rows):
                state.rows = rows
                state.isRowsFetched = true
                return .none

            case .rows:
                return .none

            case .logoutPressed:
                state.alert = logoutAlert
                return .none

            case .alert(.presented(.logout)):
                state.$loggedin.withLock { $0 = false }
                return .none

            case .downloadComponent:
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .forEach(\.rows, action: \.rows) {
            Self()
        }
    }

    private var logoutAlert: AlertState<Action.Alert> {
        AlertState {
            TextState("Do you want Logout?")
        } actions: {
            ButtonState(role: .destructive, action: .send(.logout)) {
                TextState("Logout")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
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

    private func fetchObjects(state: State) -> Effect<Self.Action> {
        let bucket = state.bucketName
        let path = state.path

        return .run { send in
            await send(.fetchResponse(TaskResult {
                try await s3Bucket.getObjects(bucket: bucket, prefix: path)
            }))
        }
    }

    private func transformObjectsToRows(state: State, objects: [S3BucketObject]) -> Effect<Self.Action> {
        return .run { send in

            var rows = objects.compactMap { (object) -> State? in
                guard let name = object.key.split(separator: "/").last else { return nil }
                let existsLocally = s3Bucket.localFileExists(for: object.key)
                return State(
                    name: String(name),
                    isFile: object.isFile,
                    path: object.key,
                    existsLocally: existsLocally
                )
            }
            rows.sort(using: SortDescriptor(\.name, order: state.order))
            await send(.set(IdentifiedArrayOf(uniqueElements: rows)), animation: .default)
        }
    }

    private func loginIntoS3(state: State) -> Effect<Self.Action> {
        let bucket = state.bucketName
        return .run { send in
            await send(
                .loginS3Response (
                    TaskResult {
                        try await s3Bucket.login(
                            bucket: bucket,
                            accessKey: keychain.accessKey,
                            secret: keychain.secret,
                            region: keychain.region
                        )
                    }
                )
            )
        }
    }
}
