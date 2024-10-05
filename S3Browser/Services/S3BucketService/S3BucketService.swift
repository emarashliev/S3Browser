//
//  S3BucketService.swift
//  S3Browser
//
//  Created by Emil Marashliev on 30.09.24.
//

import AWSS3
import ComposableArchitecture
import Foundation

enum S3BucketServiceError: Error, LocalizedError {
    case missingClient(String)

    var errorDescription: String? {
        get {
            switch self {
            case .missingClient(let msg):
                return "\(msg) (S3BucketServiceError.missingClient)"
            }
        }
    }
}

protocol S3Bucket {
    var loggedin: Bool { get }
    func getBucketRegion(bucket: String, accessKey: String, secret: String) async throws -> String
    func login(accessKey: String, secret: String, region: String) async throws
    func getObjects(bucket: String, prefix: String ) async throws -> [S3BucketObject]
}

final class S3BucketService: S3Bucket {
    var loggedin = false

    private var client: S3Client?

    func getBucketRegion(bucket: String, accessKey: String, secret: String) async throws -> String {
        let constructor = S3ClientConstructor(accessKey: accessKey, secret: secret)
        let client = try await constructor.getClient()
        let bucketLocator = S3BucketLocator(bucket: bucket, client: client)
        return try await bucketLocator.getLocation()
    }
    
    func login(accessKey: String, secret: String, region: String) async throws {
        loggedin = true
        let constructor = S3ClientConstructor(accessKey: accessKey, secret: secret, region: region)
        client = try await constructor.getClient()
    }

    func getObjects(bucket: String, prefix: String = "") async throws -> [S3BucketObject] {
        guard let client = self.client else {
            throw S3BucketServiceError.missingClient("Need to login before calling getObjectKeys(_:)")
        }

        let input = ListObjectsV2Input(bucket: bucket, delimiter: "/", prefix: prefix)
        let output = try await client.listObjectsV2(input: input)
        
        var contents = output.contents?.compactMap {
            guard let key = $0.key else { return nil }
             return S3BucketObject(name: key, prefix: prefix, isFile: true)
        } ?? [S3BucketObject]()

        let commonPrefixes = output.commonPrefixes?.compactMap{
            guard let key = $0.prefix else { return nil }
            return S3BucketObject(name: key, prefix: prefix, isFile: false)
        } ?? [S3BucketObject]()

        contents.append(contentsOf: commonPrefixes)
        return contents
    }
}

extension DependencyValues {
    var s3Bucket: any S3Bucket {
        get { self[S3BucketKey.self] }
        set { self[S3BucketKey.self] = newValue }
    }
    
    private enum S3BucketKey: DependencyKey {
        static let liveValue: any S3Bucket = S3BucketService()
    }
}

