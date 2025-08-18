import Foundation

class SQLiteEncryptionHandler {
    private let keychainAccessGroup: String?
    private let keychainItemAccount = "com.miracl.keys.userstable"

    init(keychainAccessGroup: String?) {
        self.keychainAccessGroup = keychainAccessGroup
    }

    func createEncryptionKey() -> String? {
        var data = Data(count: 256)
        _ = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 256, $0.baseAddress!)
        }

        let key = data.base64EncodedString()
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainItemAccount,
            kSecValueData as String: data.base64EncodedData(),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Add keychain access group if needed.
        if let keychainAccessGroup {
            addQuery[kSecAttrAccessGroup as String] = keychainAccessGroup
        }

        let result: OSStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard result == errSecSuccess else {
            return nil
        }

        return key
    }

    func loadEncryptionKey() -> String? {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecAttrAccount as String: keychainItemAccount,
                                    kSecReturnData as String: true]

        // Add keychain access group if needed.
        if let keychainAccessGroup {
            query[kSecAttrAccessGroup as String] = keychainAccessGroup
        }

        var queryResult: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &queryResult)
        if let data = queryResult as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    func updateEncryptionKeyAccessGroupIfNeeded() -> Bool {
        if let keychainAccessGroup {
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                        kSecMatchLimit as String: kSecMatchLimitOne,
                                        kSecAttrAccount as String: keychainItemAccount,
                                        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                        kSecAttrAccessGroup as String: keychainAccessGroup,
                                        kSecReturnData as String: true]
            var queryResult: AnyObject?
            SecItemCopyMatching(query as CFDictionary, &queryResult)

            if queryResult == nil {
                let getItemQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: keychainItemAccount
                ]

                let updatedAttributes = [
                    kSecAttrAccessGroup as String: keychainAccessGroup
                ]

                let result: OSStatus = SecItemUpdate(getItemQuery as CFDictionary, updatedAttributes as CFDictionary)
                if result == errSecSuccess {
                    return true
                } else {
                    return false
                }
            }
        }

        return true
    }

    func updateEncryptionKeyAccessibilityIfNeeded() -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecAttrAccount as String: keychainItemAccount,
                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                    kSecReturnData as String: true]
        var queryResult: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &queryResult)

        if queryResult == nil {
            let getItemQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keychainItemAccount
            ]

            var updatedAttributes = [
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]

            if let keychainAccessGroup {
                let keychainAccessGroup: CFString = keychainAccessGroup as NSString
                updatedAttributes[kSecAttrAccessGroup as String] = keychainAccessGroup
            }

            let result: OSStatus = SecItemUpdate(getItemQuery as CFDictionary, updatedAttributes as CFDictionary)
            if result == errSecSuccess {
                return true
            } else {
                return false
            }
        }

        return true
    }
}
