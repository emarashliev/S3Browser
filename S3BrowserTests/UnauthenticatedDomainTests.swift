//
//  UnauthenticatedDomainTests.swift
//  S3Browser
//
//  Created by Emil Marashliev on 20.11.24.
//


import ComposableArchitecture
import Testing
@testable import S3Browser

@MainActor
struct UnauthenticatedDomainTests {
    let testS3Bucket: any S3Bucket = TestS3BucketService()
    let testKeychain: any Keychain = TestKeychainService()
    private let state = {
        let testAccessKey = "testAccessKey"
        let testBucket = "testBucket"
        let testRegion = "testRegion"
        let testSecret = "testSecret"
        
        return UnauthenticatedDomain.State(
            accessKey: testAccessKey,
            secret: testSecret,
            bucket: testBucket,
            region: testRegion
        )
    }()
    
    @Test
    func testBinding() async {
        let store = TestStore(initialState: UnauthenticatedDomain.State()) {
            UnauthenticatedDomain()
        }
        
        store.exhaustivity = .off
        
        await store.send(.binding(.set(\.accessKey, "testAccessKey"))) {
            $0.accessKey = "testAccessKey"
        }
        
        await store.send(.binding(.set(\.bucket, "testBucket"))) {
            $0.bucket = "testBucket"
        }
        
        await store.send(.binding(.set(\.secret, "testSecret"))) {
            $0.secret = "testSecret"
            $0.isComplete = false
        }
        
        await store.send(.binding(.set(\.region, "testRegion"))) {
            $0.region = "testRegion"
            $0.isComplete = true
        }
    }
    
    @Test
    func testSignInPressed_SuccessfulLogin() async {
        let store = TestStore(initialState: state) {
            UnauthenticatedDomain()
        } withDependencies: {
            $0.s3Bucket = testS3Bucket
            $0.keychain = testKeychain
        }
        
        store.exhaustivity = .off
        
        await store.send(.signInPressed) {
            $0.isLoading = true
        }
        
        await store.receive(\.successfulLogin) {
            $0.isLoading = true
        }
    }
    
    @Test
    func testSignInPressed_HandleError() async {
        let store = TestStore(initialState: state) {
            UnauthenticatedDomain()
        } withDependencies: {
            $0.s3Bucket = TestS3BucketServiceThrows()
        }
        
        store.exhaustivity = .off
        
        await store.send(.signInPressed) {
            $0.isLoading = true
        }
        
        await store.receive(\.handleError) {
            $0.isLoading = false
            $0.alert = AlertState {
                TextState("Test error")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("OK")
                }
            }
        }
    }
    
    @Test
    func testSetRegion() async {
        let store = TestStore(initialState: state) {
            UnauthenticatedDomain()
        }
        
        await store.send(.set(region: "testRegion_tets")) {
            $0.region = "testRegion_tets"
            $0.isComplete = true
        }
    }
    
    @Test
    func testSuccessfulKeychainSave() async {
        let store = TestStore(initialState: state) {
            UnauthenticatedDomain()
        } withDependencies: {
            class TestKeychainServiceSave: TestKeychainService {
                override func set(value: String, key: KeychainServiceKey) async throws(KeychainServiceError) {
                    if key == .accessKey {
                        #expect(value == "testAccessKey")
                    } else if key == .secret {
                        #expect(value == "testSecret")
                    } else if key == .region {
                        #expect(value == "testRegion")
                    }
                }
            }
            $0.keychain = TestKeychainServiceSave()
        }
        
        store.exhaustivity = .off
        
        await store.send(.successfulLogin)
        
        await store.receive(\.successfulKeychainSave) {
            $0.$loggedin.withLock { $0 = true }
            $0.isLoading = false
        }
    }
}
