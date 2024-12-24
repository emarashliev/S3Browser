//
//  KeychainServiceKeyTests.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import Testing
@testable import S3Browser

struct KeychainServiceKeyTests {
    
    @Test("Test keychain clear")
    func clear() async throws {
        let keychain = KeychainService()
        
        try await keychain.clear()
        
        await #expect(throws: KeychainServiceError.decodeError("Can not decode accessKey value")) {
            try await keychain.accessKey
        }

    }
    
    @Test("Test if access key is set")
    func setAccessKey() async throws {
        let value = "AKIA6N5HCFHN7KA6VYVS"
        let keychain = KeychainService()
        try await keychain.clear()
        
        await #expect(throws: Never.self) {  try await keychain.set(value: value, key: .accessKey) }

        await #expect(throws: Never.self) { try await keychain.accessKey }
        #expect(try await keychain.accessKey == value)
    }
    
    @Test("Test if secret is set")
    func setSecret() async throws {
        let value = "5hqiRqvcby12wnK+aJUMvgbf9VURzSiFsTyTSQbd"
        let keychain = KeychainService()
        try await keychain.clear()
        
        await #expect(throws: Never.self) { try await keychain.set(value: value, key: .secret) }

        await #expect(throws: Never.self) { try await keychain.secret }
        #expect(try await keychain.secret == value)
    }
    
    @Test("Test if region is set")
    func setRegion() async throws {
        let value = "us-east-1"
        let keychain = KeychainService()
        try await keychain.clear()
        
        await #expect(throws: Never.self) { try await keychain.set(value: value, key: .region) }

        await #expect(throws: Never.self) { try await keychain.region }
        #expect(try await keychain.region == value)
    }
}
