//
//  KeychainService.swift
//  S3Browser
//
//  Created by Emil Marashliev on 28.09.24.
//

import Foundation

enum KeychainServiceError: Error, LocalizedError {
    case setError(String)
    case clearError(String)
    case getError(String)
    case decodeError(String)
    
    var errorDescription: String? {
        get {
            switch self {
            case .setError(let msg):
                return "\(msg) (KeychainServiceError.setError)"
            case .clearError(let msg):
                return "\(msg) (KeychainServiceError.clearError)"
            case .getError(let msg):
                return "\(msg) (KeychainServiceError.getError)"
            case .decodeError(let msg):
                return "\(msg) (KeychainServiceError.decodeError)"
            }
        }
    }
}

enum KeychainServiceKey: String {
    case accessKey
    case secret
    case region
    case bucket
}

actor KeychainService {
    var isSingedIn: Bool {
        get throws {
            try accessKey != nil && secret != nil && bucket != nil
        }
    }
    
    var accessKey: String? {
        get throws(KeychainServiceError) {
            if let data = try self.get(key: .accessKey) {
                return String(data: data, encoding: .utf8)
            }
            throw .decodeError("Data for accessKey is nil")
        }
    }
    
    var secret: String? {
        get throws(KeychainServiceError) {
            if let data = try self.get(key: .secret) {
                return String(data: data, encoding: .utf8)
            }
            throw .decodeError("Data for secret is nil")
        }
    }
    
    var region: String? {
        get throws(KeychainServiceError) {
            if let data = try self.get(key: .region) {
                return String(data: data, encoding: .utf8)
            }
            throw .decodeError("Data for region is nil")
        }
    }
    
    var bucket: String? {
        get throws(KeychainServiceError) {
            if let data = try self.get(key: .bucket) {
                return String(data: data, encoding: .utf8)
            }
            throw .decodeError("Data for bucket is nil")
        }
    }
    
    func set(value: String, key: KeychainServiceKey) throws(KeychainServiceError) {
        guard let value = value.data(using: .utf8) else {
            throw .decodeError("Can not decode the string value to data")
        }
        
        let query: [CFString : Any] = [
            kSecClass          : kSecClassGenericPassword,
            kSecAttrAccount    : key.rawValue,
            kSecValueData      : value,
            kSecAttrAccessible : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let resultCode = SecItemAdd(query as CFDictionary, nil)
        if resultCode != noErr {
            throw .setError("Can not add item, OSStatus: \(resultCode)")
        }
    }
    
    func clear() throws(KeychainServiceError) {
        let query: [CFString : Any] = [kSecClass : kSecClassGenericPassword]
        let resultCode = SecItemDelete(query as CFDictionary)
        
        if resultCode != noErr {
            throw .clearError("Can not clear the keychain, OSStatus: \(resultCode)")
        }
    }
    
    private func get(key: KeychainServiceKey) throws(KeychainServiceError) -> Data? {
        let query: [CFString: Any] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key.rawValue,
            kSecMatchLimit  : kSecMatchLimitOne,
            kSecReturnData  : kCFBooleanTrue as Any
        ]
        
        var result: AnyObject?
        let resultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if resultCode == noErr {
            return result as? Data
        } else {
            throw .getError("Can not get value for \(key.rawValue), OSStatus: \(resultCode)")
        }
    }
}
