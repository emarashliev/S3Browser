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
    
    @Test
    func onAppearHappyPathToSet() async {
        let state = FileBrowserDomain.State(id:  UUID(0), name: "root", isFile: false, path: "", rows: [])
        state.$loggedin.withLock { $0 = true }
        
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
            #expect(file1.name == "file1.txt")
            #expect(file1.isFile == true)
            #expect(file1.downloadComponent.mode == .downloaded)

            let file2 = $0.rows[1]
            #expect(file2.name == "file2.txt")
            #expect(file2.downloadComponent.mode == .downloaded)

            let subfolder = $0.rows[2]
            #expect(subfolder.name == "subfolder")
            #expect(subfolder.isFile == false)
        }
    }
}
