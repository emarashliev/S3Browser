//
//  AppCoreTests.swift
//  AppCoreTests
//
//  Created by Emil Marashliev on 27.09.24.
//

import Testing
import ComposableArchitecture
@testable import S3Browser

@MainActor
struct AppCoreTests {

    @Test
    func basics() async throws {
        let store = TestStore(initialState: AppCoreDomain.State()) {
            AppCoreDomain()
        }
        

        await store.send(AppCoreDomain.Action.loggedOut(.successfulKeychainSave)){
            $0 = AppCoreDomain.State.loggedIn(.init())
          }
    }

}
