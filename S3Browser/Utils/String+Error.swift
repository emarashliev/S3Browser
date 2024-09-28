//
//  String+Error.swift
//  S3Browser
//
//  Created by Emil Marashliev on 28.09.24.
//

import Foundation

extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
    public var errorDescription: String? { return self }
}
