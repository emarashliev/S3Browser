//
//  S3SBucketLocator.swift
//  S3Browser
//
//  Created by Emil Marashliev on 28.09.24.
//

import AWSS3
import Foundation

enum S3BucketLocatorError: Error, LocalizedError {
    case missingContents(String)
    
    var errorDescription: String? {
        get {
            switch self {
            case .missingContents(let msg):
                return "\(msg) (S3BucketLocationServiceError.missingContents)"
            }
        }
    }
}

struct S3BucketLocator {
    private let bucket: String
    private let client: S3Client
    
    init(bucket: String, client: S3Client) {
        self.bucket = bucket
        self.client = client
    }
    
    func getLocation() async throws -> String {
        let input = GetBucketLocationInput(bucket: bucket)
        let bucketLocation = try await client.getBucketLocation(input: input)
        guard let location = bucketLocation.locationConstraint?.rawValue else {
            throw S3BucketLocatorError.missingContents("Can not find location for bucket with name \(bucket)")
        }
        
        return location
    }

}
