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
        var name: String = ""
        let isFile: Bool
        var path: String = ""
        var rows: IdentifiedArrayOf<State> = []
        @Shared(.appStorage("logged")) var loggedin = false
        @Shared(.appStorage("bucket-name")) var bucketName = ""

        init(
            id: UUID? = nil,
            name: String = "",
            isFile: Bool,
            path: String = "",
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
        case logoutPressed
        case onAppear
        indirect case rows(IdentifiedActionOf<FIleBrowserDomain>)
    }

    @Dependency(\.s3Bucket) var s3Bucket
    @Dependency(\.keychain) var keychain

    var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                let bucket = state.bucketName
                return .run { _ in
                    if !s3Bucket.loggedin {
                        try await s3Bucket.login(
                            accessKey: keychain.accessKey,
                            secret: keychain.secret,
                            region: keychain.region
                        )
                    }
                    let objects = try await s3Bucket.getObjects(bucket: bucket, prefix: "")
                    print(objects)
                }

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
}
