//
//  AuthenticatedDomain.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import ComposableArchitecture

@Reducer
struct AuthenticatedDomain {
    
    @ObservableState
    struct State: Equatable {
        let bucket: String
    }
    
    enum Action: Equatable {
        case successfulLogout
        case onAppear
    }

    @Dependency(\.keychain) var keychain
    @Dependency(\.s3Bucket) var s3Bucket

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .successfulLogout:
                return .run { _ in
                    try await keychain.clear()
                }
            case .onAppear:
                let bucket = state.bucket
                return .run { _ in
                    if !s3Bucket.loggedin {
                        try await s3Bucket.login(
                            accessKey: keychain.accessKey,
                            secret: keychain.secret,
                            region: keychain.region
                        )
                    }
                    let r = try await s3Bucket.getObjectKeys(bucket: bucket)
                    print(r)
                }
            }
        }
    }
}
