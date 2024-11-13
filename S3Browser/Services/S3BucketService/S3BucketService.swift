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
    case getObjectBody(String)
    case readGetObjectBody(String)

    var errorDescription: String? {
        get {
            switch self {
            case let .missingClient(msg):
                return "\(msg) (S3BucketServiceError.missingClient)"

            case let .getObjectBody(msg):
                return "\(msg) (S3BucketServiceError.getObjectBody)"
                
            case let .readGetObjectBody(msg):
                return "\(msg) (S3BucketServiceError.readGetObjectBody)"

            }
        }
    }
}

protocol S3Bucket {
    var loggedin: Bool { get }
    func getBucketRegion(bucket: String, accessKey: String, secret: String) async throws -> String
    func login(bucket: String, accessKey: String, secret: String, region: String) async throws
    func getObjects(bucket: String, prefix: String ) async throws -> [S3BucketObject]
    func downloadFile(bucket: String, key: String) async throws
    func localFileExists(for key: String) -> Bool
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
    
    func login(bucket: String, accessKey: String, secret: String, region: String) async throws {
        let constructor = S3ClientConstructor(accessKey: accessKey, secret: secret, region: region)
        client = try await constructor.getClient()
        _ = try await getObjects(bucket: bucket)
        loggedin = true
    }

    func getObjects(bucket: String, prefix: String = "") async throws -> [S3BucketObject] {
        guard let client = self.client else {
            throw S3BucketServiceError.missingClient("Need to login before calling getObjectKeys(_:)")
        }

        let input = ListObjectsV2Input(bucket: bucket, delimiter: "/", prefix: prefix)
        let output = try await client.listObjectsV2(input: input)
        
        var contents = output.contents?.compactMap {
            guard let key = $0.key else { return nil }
             return S3BucketObject(key: key, prefix: prefix, isFile: true)
        } ?? [S3BucketObject]()

        let commonPrefixes = output.commonPrefixes?.compactMap{
            guard let key = $0.prefix else { return nil }
            return S3BucketObject(key: key, prefix: prefix, isFile: false)
        } ?? [S3BucketObject]()

        contents.append(contentsOf: commonPrefixes)
        contents.removeAll { $0.key == prefix }
        return contents
    }

    func downloadFile(bucket: String, key: String) async throws {
        guard let client = self.client else {
            throw S3BucketServiceError.missingClient("Need to login before calling getObjectKeys(_:)")
        }

        let input = GetObjectInput(bucket: bucket, key: key)
        let output = try await client.getObject(input: input)
        let url = try await client.presignedURLForGetObject(input: input, expiration: 1000)
        guard let body = output.body else {
            throw S3BucketServiceError.getObjectBody("GetObjectInput missing body.")
        }

        guard let data = try await body.readData() else {
            throw S3BucketServiceError.readGetObjectBody("GetObjectInput unable to read data.")
        }

        let fileUrl = getDocumentsDirectory().appendingPathComponent(encodeLocalName(for: key))
        try data.write(to: fileUrl)
    }

    func localFileExists(for key: String) -> Bool {
        let fileUrl = getDocumentsDirectory().appendingPathComponent(encodeLocalName(for: key))
        return FileManager.default.fileExists(atPath: fileUrl.path())
    }

    private func encodeLocalName(for key: String) -> String {
        return key.replacingOccurrences(of: "/", with: "_")
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
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

