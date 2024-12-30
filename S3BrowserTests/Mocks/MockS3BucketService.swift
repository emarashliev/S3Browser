//
//  TestS3BucketService.swift
//  S3Browser
//
//  Created by Emil Marashliev on 21.11.24.
//

import Foundation
@testable import S3Browser

class MockS3BucketService: S3Bucket {
    static let file1 = "folder/file1.txt"
    static let file2 = "folder/file2.txt"
    static let subfolder = "folder/subfolder/"

    var loggedin = false
    
    func getBucketRegion(bucket: String, accessKey: String, secret: String) async throws -> String {
        "us-east-1"
    }
    
    func login(bucket: String, accessKey: String, secret: String, region: String) async throws {
    }
    
    func getObjects(bucket: String, prefix: String) async throws -> [S3Browser.S3BucketObject] {
        [
            S3BucketObject(key: Self.file1, prefix: "", isFile: true),
            S3BucketObject(key: Self.file2, prefix: "", isFile: true),
            S3BucketObject(key: Self.subfolder, prefix: "", isFile: false)
        ]
    }
    
    func downloadFile(bucket: String, key: String) async throws {
    }
    
    func localFileExists(for key: String) -> Bool {
        true
    }
}


class MockS3BucketServiceThrows: MockS3BucketService {
    struct LoginError: Error, LocalizedError {
        static let errorDescription: String = "Test login error"
        var errorDescription: String? { Self.errorDescription }
    }

    struct GetObjectsError: Error, LocalizedError {
        static let errorDescription: String = "Test get objects error"
        var errorDescription: String? { Self.errorDescription }
    }
}

class MockS3BucketServiceThrowsOnLogin: MockS3BucketServiceThrows {
    override func login(bucket: String, accessKey: String, secret: String, region: String) async throws {
        throw LoginError()
    }
}

class MockS3BucketServiceThrowsOnGetObjects: MockS3BucketServiceThrows {
    override func getObjects(bucket: String, prefix: String) async throws -> [S3BucketObject] {
        throw GetObjectsError()
    }
}
