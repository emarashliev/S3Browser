//
//  FileManager.swift
//  S3Browser
//
//  Created by Emil Marashliev on 30.12.24.
//

import Foundation

extension FileManager {

    static func fileURL(for fileKey: String) -> URL {
        let path = fileKey.replacingOccurrences(of: "/", with: "_")
        return getDocumentsDirectory().appendingPathComponent(path)
    }

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
