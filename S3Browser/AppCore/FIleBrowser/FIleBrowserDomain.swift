//
//  FIleBrowserDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 4.10.24.
//

import ComposableArchitecture
import Foundation

@Reducer
struct FIleBrowserDomain {

    @ObservableState
    struct State: Equatable, Identifiable {
        let id: UUID
        var name: String
        let isFile: Bool
        var path: String
        var rows: IdentifiedArrayOf<State> = []
        @Shared(.appStorage("logged")) var loggedin = false
        @Shared(.appStorage("bucket-name")) var bucketName = ""

        init(
            id: UUID? = nil,
            name: String,
            isFile: Bool,
            path: String = "" ,
            rows: IdentifiedArrayOf<State> = []
        ) {
            @Dependency(\.uuid) var uuid
            self.id = id ?? uuid()
            self.name = name
            self.rows = rows
            self.isFile = isFile
            self.path = path
        }
    }

    enum Action: Equatable {
        case onAppear
        case successfulLoginInS3
        case set(IdentifiedArrayOf<State>)
        indirect case rows(IdentifiedActionOf<FIleBrowserDomain>)
        case logoutPressed
    }

    @Dependency(\.s3Bucket) var s3Bucket
    @Dependency(\.keychain) var keychain

    var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return loginIfNeeded(state: &state)

            case .successfulLoginInS3:
                return fetchBucketObjects(state: &state)

            case let .set(rows):
                state.rows = rows
                return .none

            case .rows:
                return .none

            case .logoutPressed:
                state.loggedin = false
                return .none

            }
        }
        .forEach(\.rows, action: \.rows) {
            Self()
        }
    }

    private func fetchBucketObjects(state: inout State) -> Effect<Self.Action> {
        let bucket = state.bucketName
        let path = state.path

        return .run { send in
            
            let objects = try await s3Bucket.getObjects(bucket: bucket, prefix: path)
            let rows = objects.compactMap{ (object) -> State? in
                guard let name = object.key.split(separator: "/").last else {return nil }
                return State(name: String(name), isFile: object.isFile, path: object.key)
            }

            await send(.set(IdentifiedArrayOf(uniqueElements: rows)))
        }
    }

    private func loginIfNeeded(state: inout State) -> Effect<Self.Action> {
        return .run { send in
            if !s3Bucket.loggedin {
                try await s3Bucket.login(
                    accessKey: keychain.accessKey,
                    secret: keychain.secret,
                    region: keychain.region
                )
            }
            await send(.successfulLoginInS3)
        }
    }
}
