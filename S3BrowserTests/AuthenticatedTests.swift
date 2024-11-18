//
//  AuthenticatedTests.swift
//  S3Browser
//
//  Created by Emil Marashliev on 22.10.24.
//

import Testing
import ComposableArchitecture
@testable import S3Browser

@MainActor
struct AuthenticatedTests {

    @Test
    func successfulKeychainClear() async throws {
        let state = AuthenticatedDomain.State()
        state.$bucketName.withLock { $0 = "test" }
        let store = TestStore(initialState: state) {
            AuthenticatedDomain()
        }

        await store.send(AuthenticatedDomain.Action.successfulKeychainClear) {
            $0.bucketName = ""
        }
    }
}
