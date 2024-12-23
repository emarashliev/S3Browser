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
        [
            S3BucketObject(key: "folder/file1.txt", prefix: "", isFile: true),
            S3BucketObject(key: "folder/file2.txt", prefix: "", isFile: true),
            S3BucketObject(key: "folder/subfolder/", prefix: "", isFile: false)
        ]
    }
    
    func downloadFile(bucket: String, key: String) async throws {
        
    }
    
    func localFileExists(for key: String) -> Bool {
        true
    }
}

class TestS3BucketServiceThrows: MockS3BucketService {
    struct LoginError: Error, LocalizedError {
        var errorDescription: String? { "Test login error" }
    }
    
    struct GetObjectsError: Error, LocalizedError {
        var errorDescription: String? { "Test get objects error" }
    }
    
    static let loginError: Error = LoginError()
    static let getObjectsError: Error = GetObjectsError()
    
    override func login(bucket: String, accessKey: String, secret: String, region: String) async throws {
        throw Self.loginError
    }
    
    override func getObjects(bucket: String, prefix: String) async throws -> [S3Browser.S3BucketObject] {
        throw Self.getObjectsError
    }
}
