//
//  S3SBucketLocationService.swift
//  S3Browser
//
//  Created by Emil Marashliev on 28.09.24.
//

import AWSS3

enum S3BucketLocationServiceError: Error {
    case missingContents(String)
}

struct S3BucketLocationService {
    
    
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
            throw S3BucketLocationServiceError.missingContents("Can not find location for bucket with name \(bucket)")
        }
        
        return location
    }

}
