//
//  AuthenticatedDomainTests.swift
//  S3Browser
//
//  Created by Emil Marashliev on 22.10.24.
//

import Testing
import ComposableArchitecture
@testable import S3Browser

@MainActor
struct AuthenticatedDomainTests {
    private let mockS3Bucket: any S3Bucket = MockS3BucketService()
    private let mockKeychain: any Keychain = MockKeychainService()
    
    @Test("Loggedin publisher")
    func onAppearLoggedinPublisher() async {
        let store = TestStore(initialState: AuthenticatedDomain.State(loggedin: false)) {
            AuthenticatedDomain()
        } withDependencies: {
            $0.keychain = mockKeychain
        }
        store.exhaustivity = .off

        // Simulate the `onAppear` action to check if `loggedin` is published correctly
        await store.send(.onAppear)
        await store.receive(\.loggedin) {
            $0.$loggedin.withLock { $0 = false }
        }
    }
    
    @Test("Loggedout publisher")
    func loggedinLogoutTriggered() async {
        let store = TestStore(initialState: AuthenticatedDomain.State(loggedin: true)) {
            AuthenticatedDomain()
        } withDependencies: {
            $0.keychain = mockKeychain
        }
        store.exhaustivity = .off
        
        // Simulate logged out state
        await store.send(.loggedin(false))
        await store.receive(\.successfulLogout)
    }
    
    @Test("Successful keychain clear publisher")
    func successfulLogoutKeychainCleared() async {
        let store = TestStore(initialState: AuthenticatedDomain.State(loggedin: true)) {
            AuthenticatedDomain()
        } withDependencies: {
            $0.keychain = mockKeychain
            $0.s3Bucket = mockS3Bucket
        }
        store.exhaustivity = .off

        await store.send(.successfulLogout)
        await store.receive(\.successfulKeychainClear) {
            $0.$bucketName.withLock { $0 = "" }
        }
    }

    @Test("Successful keychain clear and bucket name reset publisher")
    func successfulKeychainClearBucketNameReset() async {
        let store = TestStore(initialState: AuthenticatedDomain.State(loggedin: true, bucketName: "test-bucket")) {
            AuthenticatedDomain()
        } withDependencies: {
            $0.keychain = mockKeychain
            $0.s3Bucket = mockS3Bucket
        }
        store.exhaustivity = .off

        // Simulate successful keychain clear
        await store.send(.successfulKeychainClear) {
            $0.$bucketName.withLock { $0 = "" }
        }
    }
    
    @Test("Successful keychain clear publisher")
    func successfulKeychainClear() async throws {
        let state = AuthenticatedDomain.State()
        state.$bucketName.withLock { $0 = "test" }
        let store = TestStore(initialState: state) {
            AuthenticatedDomain()
        }

        await store.send(AuthenticatedDomain.Action.successfulKeychainClear) {
            $0.$bucketName.withLock { $0 = "" }
        }
    }
}
