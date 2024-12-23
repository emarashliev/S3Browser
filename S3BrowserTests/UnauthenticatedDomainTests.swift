//
//  UnauthenticatedDomainTests.swift
//  S3Browser
//
//  Created by Emil Marashliev on 20.11.24.
//


import ComposableArchitecture
import Testing
@testable import S3Browser


fileprivate struct Cnstants {
    static let accessKey = "testAccessKey_initial"
    static let bucket = "testBucket_initial"
    static let region = "testRegion_initial"
    static let secret = "testSecret_initial"
}

@MainActor
struct UnauthenticatedDomainTests {
    private let mockS3Bucket: any S3Bucket = MockS3BucketService()
    private let mockKeychain: any Keychain = MockKeychainService()
    private let state = {
        UnauthenticatedDomain.State(
            accessKey: Cnstants.accessKey,
            secret: Cnstants.secret,
            bucket: Cnstants.bucket,
            region: Cnstants.region
        )
    }()
    
    @Test("UnauthenticatedDomain binding")
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
    
    @Test("Successful login")
    func signInPressedSuccessfulLogin() async {
        let store = TestStore(initialState: state) {
            UnauthenticatedDomain()
        } withDependencies: {
            $0.s3Bucket = mockS3Bucket
            $0.keychain = mockKeychain
        }
        store.exhaustivity = .off
        
        await store.send(.signInPressed) {
            $0.isLoading = true
        }
        
        await store.receive(\.successfulLogin) {
            $0.isLoading = true
        }
    }
    
    @Test("Handle sign in error")
    func signInPressedHandleError() async {
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
                TextState(TestS3BucketServiceThrows.loginError.localizedDescription)
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("OK")
                }
            }
        }
    }
    
    @Test("Set region")
    func setRegion() async {
        let store = TestStore(initialState: state) {
            UnauthenticatedDomain()
        }
        
        await store.send(.set(region: "testRegion")) {
            $0.region = "testRegion"
            $0.isComplete = true
        }
    }
    
    @Test("Successful keychain save")
    func successfulKeychainSave() async {
        let store = TestStore(initialState: state) {
            UnauthenticatedDomain()
        } withDependencies: {
            class TestKeychainServiceSave: MockKeychainService {
                override func set(value: String, key: KeychainServiceKey) async throws(KeychainServiceError) {
                    if key == .accessKey {
                        #expect(value == Cnstants.accessKey)
                    } else if key == .secret {
                        #expect(value == Cnstants.secret)
                    } else if key == .region {
                        #expect(value == Cnstants.region)
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
