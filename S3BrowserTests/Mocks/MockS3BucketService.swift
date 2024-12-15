//
//  TestS3BucketService.swift
//  S3Browser
//
//  Created by Emil Marashliev on 21.11.24.
//

import Foundation
@testable import S3Browser

class MockS3BucketService: S3Bucket {
    var loggedin = false
    
    func getBucketRegion(bucket: String, accessKey: String, secret: String) async throws -> String {
        "us-east-1"
    }
    
    func login(bucket: String, accessKey: String, secret: String, region: String) async throws {
        
    }
    
    func getObjects(bucket: String, prefix: String) async throws -> [S3Browser.S3BucketObject] {
        []
    }
    
    func downloadFile(bucket: String, key: String) async throws {
        
    }
    
    func localFileExists(for key: String) -> Bool {
        true
    }
}

struct TestS3BucketServiceTestError: Error, LocalizedError {
    var errorDescription: String? { "Test error" }
}

class TestS3BucketServiceThrows: MockS3BucketService {
    
    override func login(bucket: String, accessKey: String, secret: String, region: String) async throws {
        throw TestS3BucketServiceTestError()
    }
}
