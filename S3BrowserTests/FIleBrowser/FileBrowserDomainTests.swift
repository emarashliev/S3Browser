//
//  FileBrowserDomainTests.swift
//  S3BrowserTests
//
//  Created by Emil Marashliev on 15.12.24.
//

import Foundation
import Testing
import ComposableArchitecture
@testable import S3Browser


@MainActor
struct FileBrowserDomainTests {
    private let state = {
        let state = FileBrowserDomain.State(id:  UUID(0), name: "root", isFile: false, path: "", rows: [])
        state.$loggedin.withLock { $0 = true }
        state.$bucketName.withLock { $0 = "bucket" }
        return state
    }()

    @Test("Test happy path, from .onAppear to .set(rows)")
    func onAppearHappyPathToSet() async {

        let store = TestStore(initialState: state) {
            FileBrowserDomain()
        } withDependencies: {
            $0.s3Bucket = MockS3BucketService()
            $0.keychain = MockKeychainService()
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        // happy path chain triggering
        // .onAppear -> .loginS3 -> .loginS3Response.success -> .fetchObjects -> .fetchResponse.success -> .set
        await store.send(.onAppear)
        await store.receive(\.loginS3)
        await store.receive(\.loginS3Response.success)
        await store.receive(\.fetchObjects)
        await store.receive(\.fetchResponse.success)
        await store.receive(\.set) {
            $0.isRowsFetched = true
            
            // Check that rows are set correctly
            #expect($0.rows.count == 3)

            let file1 = $0.rows[0]
            #expect(file1.path == MockS3BucketService.file1)
            #expect(file1.isFile == true)
            #expect(file1.downloadComponent.mode == .downloaded)

            let file2 = $0.rows[1]
            #expect(file2.path == MockS3BucketService.file2)
            #expect(file2.downloadComponent.mode == .downloaded)

            let subfolder = $0.rows[2]
            #expect(subfolder.path == MockS3BucketService.subfolder)
            #expect(subfolder.isFile == false)
        }
        await store.finish()

    }

    @Test("Test login failure path, from .onAppear to .loginS3Response.failure")
    func onLoginFailure() async {
        let store = TestStore(initialState: state) {
            FileBrowserDomain()
        } withDependencies: {
            $0.s3Bucket = MockS3BucketServiceThrowsOnLogin()
            $0.keychain = MockKeychainService()
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.loginS3)
        await store.receive(\.loginS3Response.failure)
        await store.finish()
        store.assert { state in
            let message = state.alert?.message?.customDumpValue as? String
            #expect(message != nil)
            #expect(message == MockS3BucketServiceThrows.LoginError.errorDescription)
        }
    }

    @Test("Test fetch failure path, from .onAppear to .fetchResponse.failure")
    func fetchResultFailure() async {
        let store = TestStore(initialState: state) {
            FileBrowserDomain()
        } withDependencies: {
            $0.s3Bucket = MockS3BucketServiceThrowsOnGetObjects()
            $0.keychain = MockKeychainService()
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.loginS3)
        await store.receive(\.loginS3Response.success)
        await store.receive(\.fetchObjects)
        await store.receive(\.fetchResponse.failure)
        await store.finish()
        store.assert { state in
            let message = state.alert?.message?.customDumpValue as? String
            #expect(message != nil)
            #expect(message == MockS3BucketServiceThrows.GetObjectsError.errorDescription)
        }
    }

    @Test("Test reorder rows, from .onAppear to .set(rows)")
    func reorderRows() async {
        let store = TestStore(initialState: state) {
            FileBrowserDomain()
        } withDependencies: {
            $0.s3Bucket = MockS3BucketService()
            $0.keychain = MockKeychainService()
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.loginS3)
        await store.receive(\.loginS3Response.success)
        await store.receive(\.fetchObjects)
        await store.receive(\.fetchResponse.success)
        await store.receive(\.set) { state in
            #expect(state.rows.first?.path != nil)
            #expect(state.rows.first?.path == MockS3BucketService.file1)
        }
        await store.send(.reorderRows) { state in
            #expect(state.rows.first?.path != nil)
            #expect(state.rows.first?.path == MockS3BucketService.subfolder)
        }
        await store.finish()
    }

    @Test("Test logout, from .onAppear to .alert(.presented(.logout))")
    func logout() async {
        let store = TestStore(initialState: state) {
            FileBrowserDomain()
        } withDependencies: {
            $0.s3Bucket = MockS3BucketService()
            $0.keychain = MockKeychainService()
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.loginS3)
        await store.receive(\.loginS3Response.success) { state in
            state.$loggedin.withLock { $0 = true }
        }
        await store.send(.logoutPressed) { state in
            let title = state.alert?.title.customDumpValue as? String
            #expect(title != nil)
            #expect(title == "Do you want Logout?")
        }
        await store.send(.alert(.presented(.logout))) { state in
            state.$loggedin.withLock { $0 = false }
        }
        await store.finish()
    }
}
