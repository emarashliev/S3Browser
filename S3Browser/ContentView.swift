//
//  ContentView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 27.09.24.
//

import SwiftUI
import AWSS3

enum HandlerError: Error {
    case getObjectBody(String)
    case readGetObjectBody(String)
    case missingContents(String)
}

struct ContentView: View {
    var body: some View {
        VStack {
            Button {
                Task {
                    do {
//                        try await onButtonPressed()
                        try await test2()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } label: {
                Text("Press me 😏")
            }
        }
        .padding()
    }
    
    func test2() async throws {
        let key = KeychainService()
//        try await key.set(value: "AKIA6N5HCFHN7KA6VYVS", key: .accessKey)
//        try await key.set(value: "5hqiRqvcby12wnK+aJUMvgbf9VURzSiFsTyTSQbd", key: .secret)
//        try await key.set(value: "emil-test1", key: .bucket)
//        try await key.set(value: "us-east-1", key: .region)
        
        key.clear()
        try await print(key.accessKey)
        try await print(key.secret)
        try await print(key.bucket)
        try await print(key.region)
        try await print(key.isSingedIn)
    }
    
    func onButtonPressed() async throws {
        var clientConstructor = S3ClientConstructor(
            accessKey: "AKIA6N5HCFHN7KA6VYVS",
            secret: "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"
        )
        let locationService = try S3BucketLocationService(
            bucket: "emil-test1",
            client: await clientConstructor.getClient()
        )
        clientConstructor.region = try await locationService.getLocation()
        let client = try await clientConstructor.getClient()
        
        
        let output = try await client.listObjectsV2(input: ListObjectsV2Input(bucket: "emil-test1"))
        
        let keys = output.contents!.compactMap { $0.key }
        let data = try await readFile(bucket: "emil-test1", key: keys.first!, client: client)
        print(data)
    }
    
    public func readFile(bucket: String, key: String, client: S3Client) async throws -> Data {
        let input = GetObjectInput(
            bucket: bucket,
            key: key
        )
        do {
            let output = try await client.getObject(input: input)
            
            guard let body = output.body else {
                throw HandlerError.getObjectBody("GetObjectInput missing body.")
            }
            
            guard let data = try await body.readData() else {
                throw HandlerError.readGetObjectBody("GetObjectInput unable to read data.")
            }
            
            return data
        }
        catch {
            print("ERROR: ", dump(error, name: "Reading a file."))
            throw error
        }
    }
}

#Preview {
    ContentView()
}
