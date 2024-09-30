//
//  KeychainService.swift
//  S3Browser
//
//  Created by Emil Marashliev on 28.09.24.
//

import ComposableArchitecture
import Foundation

enum KeychainServiceError: Error, LocalizedError, Equatable {
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
}


protocol Keychainable {
    var accessKey: String { get async throws }
    var secret: String { get async throws }
    var region: String { get async throws }

    func set(value: String, key: KeychainServiceKey) async throws(KeychainServiceError)
    func clear() async throws(KeychainServiceError)
}

actor KeychainService: Keychainable {
    var accessKey: String {
        get throws(KeychainServiceError) {
            guard
                let data = try self.get(key: .accessKey),
                let accessKey = String(data: data, encoding: .utf8)
            else {
                throw .decodeError("Can not decode accessKey value")
            }
            return accessKey
        }
    }
    
    var secret: String {
        get throws(KeychainServiceError) {
            guard
                let data = try self.get(key: .secret),
                let secret = String(data: data, encoding: .utf8)
            else {
                throw .decodeError("Can not decode secret value")
            }
            return secret
        }
    }
    
    var region: String {
        get throws(KeychainServiceError) {
            guard
                let data = try self.get(key: .region),
                let region = String(data: data, encoding: .utf8)
            else {
                throw .decodeError("Can not decode region value")
            }
            return region
        }
    }
    
    
    func set(value: String, key: KeychainServiceKey) async throws(KeychainServiceError) {
        guard let value = value.data(using: .utf8) else {
            throw .decodeError("Can not decode the string value to data")
        }
        
        let query: [CFString : Any] = [
            kSecClass          : kSecClassGenericPassword,
            kSecAttrAccount    : key.rawValue,
            kSecValueData      : value,
            kSecAttrAccessible : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            throw .setError("Can not add item, OSStatus: \(status)")
        }
    }
    
    func clear() throws(KeychainServiceError) {
        let query: [CFString : Any] = [kSecClass : kSecClassGenericPassword]
        let status = SecItemDelete(query as CFDictionary)
        
        if status != noErr && status != errSecItemNotFound {
            throw .clearError("Can not clear the keychain, OSStatus: \(status)")
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
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        guard status != errSecItemNotFound else { return nil }
        guard status == noErr else {
            throw .getError("Can not get value for \(key.rawValue), OSStatus: \(status)")
        }
        
        return result as? Data
    }
}

extension DependencyValues {
    var keychain: any Keychainable {
        get { self[KeychainKey.self] }
        set { self[KeychainKey.self] = newValue }
    }
    
    private enum KeychainKey: DependencyKey {
        static let liveValue: any Keychainable = KeychainService()
    }
}
