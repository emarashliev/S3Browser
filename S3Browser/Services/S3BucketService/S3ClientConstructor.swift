//
//  S3ClientConstructor.swift
//  S3Browser
//
//  Created by Emil Marashliev on 28.09.24.
//

import AWSS3
import AWSSDKIdentity

struct S3ClientConstructor {
    private let accessKey: String
    private let secret: String
    private let region: String
    
    init(accessKey: String, secret: String, region: String = "us-east-1") {
        self.accessKey = accessKey
        self.secret = secret
        self.region = region
    }
    
    func getClient() async throws -> S3Client {
        let credentialIdentity = AWSCredentialIdentity(accessKey: accessKey,secret: secret)
        let credentialIdentityResolver = try StaticAWSCredentialIdentityResolver(credentialIdentity)
        let configuration = try await S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: region
        )
        
        return S3Client(config: configuration)
    }
}
