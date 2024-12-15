//
//  TestKeychainService.swift
//  S3Browser
//
//  Created by Emil Marashliev on 21.11.24.
//

@testable import S3Browser

class TestKeychainService: Keychain {
    var accessKey: String { "testAccessKey" }
    var secret: String { "testSecret" }
    var region: String { "testRegion" }

    func set(value: String, key: KeychainServiceKey) async throws(KeychainServiceError) {
        
    }
    
    func clear() async throws(KeychainServiceError) {
        
    }
}
