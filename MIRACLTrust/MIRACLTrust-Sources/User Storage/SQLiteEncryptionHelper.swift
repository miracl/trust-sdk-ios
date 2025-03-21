import Foundation

class SQLiteEncryptionHandler {
    private let keychainItemAccount = "com.miracl.keys.userstable"

    func createEncryptionKey() -> String? {
        var data = Data(count: 256)
        _ = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 256, $0.baseAddress!)
        }

        let key = data.base64EncodedString()
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainItemAccount,
            kSecValueData as String: data.base64EncodedData(),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let result: OSStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard result == errSecSuccess else {
            return nil
        }

        return key
    }

    func loadEncryptionKey() -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecAttrAccount as String: keychainItemAccount,
                                    kSecReturnData as String: true]
        var queryResult: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &queryResult)
        if let data = queryResult as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
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

            let updatedAttribute = [
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]

            let result: OSStatus = SecItemUpdate(getItemQuery as CFDictionary, updatedAttribute as CFDictionary)
            if result == errSecSuccess {
                return true
            } else {
                return false
            }
        }

        return true
    }
}
