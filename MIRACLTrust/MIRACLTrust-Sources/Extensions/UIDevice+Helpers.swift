#if os(iOS)
    import UIKit

    extension UIDevice {
        public var modelName: String {
            var systemInfo = utsname()
            uname(&systemInfo)

            let machineMirror = Mirror(reflecting: systemInfo.machine)

            var modelIdentifier = ""

            modelIdentifier = machineMirror.children.reduce("") { identifier, child -> String in
                guard let value = child.value as? Int8, value != 0 else {
                    return identifier
                }
                let valueAsString = UnicodeScalar(UInt8(value))
                return identifier + String(valueAsString)
            }

            return userFriendlyDeviceName(modelIdentifier)
        }

        // swiftlint:disable:next function_body_length
        private func userFriendlyDeviceName(_ modelIdentifier: String) -> String {
            switch modelIdentifier {
            case "iPhone5,1", "iPhone5,2":
                return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":
                return "iPhone 5C"
            case "iPhone6,1", "iPhone6,2":
                return "iPhone 5S"
            case "iPhone7,2":
                return "iPhone 6"
            case "iPhone7,1":
                return "iPhone 6 Plus"
            case "iPhone8,1":
                return "iPhone 6S"
            case "iPhone8,2":
                return "iPhone 6S Plus"
            case "iPhone9,1", "iPhone9,3":
                return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":
                return "iPhone 7 Plus"
            case "iPhone8,4":
                return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":
                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":
                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":
                return "iPhone X"
            case "iPhone11,2":
                return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":
                return "iPhone XS Max"
            case "iPhone11,8":
                return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":
                return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":
                return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":
                return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":
                return "iPad Air"
            case "iPad5,3", "iPad5,4":
                return "iPad Air 2"
            case "iPad6,11", "iPad6,12":
                return "iPad 5"
            case "iPad7,5", "iPad7,6":
                return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":
                return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":
                return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":
                return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":
                return "iPad Mini 4"
            case "iPad11,1", "iPad11,2":
                return "iPad Mini 5"
            case "iPad14,1", "iPad14,2":
                return "iPad Mini 6"
            case "iPad6,3", "iPad6,4":
                return "iPad Pro 9.7 Inch"
            case "iPad6,7", "iPad6,8":
                return "iPadPro 12.9 Inch"
            case "iPad7,1", "iPad7,2":
                return "iPadPro 12.9 Inch 2nd Gen"
            case "iPad7,3", "iPad7,4":
                return "iPadPro 10.5 Inch"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":
                return "iPadPro 11 Inch"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":
                return "iPadPro 12.9 Inch 3rd Gen"
            case "iPad8,9", "iPad8,10":
                return "iPad Pro 11 inch 4th Gen"
            case "iPad8,11", "iPad8,12":
                return "iPad Pro 12.9 inch 4th Gen"
            case "iPad11,3", "iPad11,4":
                return "iPad Air 3rd Gen"
            case "iPad11,6", "iPad11,7":
                return " iPad 8th Gen"
            case "iPad13,1", "iPad13,2":
                return "iPad air 4th Gen"
            case "iPhone12,1":
                return "iPhone 11"
            case "iPhone12,3":
                return "iPhone 11 Pro"
            case "iPhone12,5":
                return "iPhone 11 Pro Max"
            case "iPhone12,8":
                return "iPhone SE 2nd Gen"
            case "iPhone13,1":
                return "iPhone 12 Mini"
            case "iPhone13,2":
                return "iPhone 12"
            case "iPhone13,3":
                return "iPhone 12 Pro"
            case "iPhone13,4":
                return "iPhone 12 Pro Max"
            case "iPhone14,4":
                return "iPhone 13 mini"
            case "iPhone14,5":
                return "iPhone 13"
            case "iPhone14,2":
                return "iPhone 13 Pro"
            case "iPhone14,3":
                return "iPhone 13 Pro Max"
            case "iPhone14,6":
                return "iPhone SE 3rd Gen"
            case "iPhone14,7":
                return "iPhone 14"
            case "iPhone14,8":
                return "iPhone 14 Plus"
            case "iPhone15,2":
                return "iPhone 14 Pro"
            case "iPhone15,3":
                return "iPhone 14 Pro Max"
            case "iPhone15,4":
                return "iPhone 15"
            case "iPhone15,5":
                return "iPhone 15 Plus"
            case "iPhone16,1":
                return "iPhone 15 Pro"
            case "iPhone16,2":
                return "iPhone 15 Pro Max"
            case "iPhone17,1":
                return "iPhone 16 Pro"
            case "iPhone17,2":
                return "iPhone 16 Pro Max"
            case "iPhone17,3":
                return "iPhone 16"
            case "iPhone17,4":
                return "iPhone 16 Plus"
            case "iPad12,1":
                return "iPad 9th Gen (WiFi)"
            case "iPad12,2":
                return "iPad 9th Gen (WiFi+Cellular)"
            case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":
                return "iPad Pro 11 inch 5th Gen"
            case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":
                return "iPad Pro 12.9 inch 5th Gen"
            case "iPad13,16":
                return "iPad Air 5th Gen (WiFi)"
            case "iPad13,17":
                return "iPad Air 5th Gen (WiFi+Cellular)"
            case "iPad13,18", "iPad13,19":
                return "iPad 10th Gen"
            case "iPad14,3", "iPad14,4":
                return "iPad Pro 11 inch 4th Gen"
            case "iPad14,5", "iPad14,6":
                return "iPad Pro 12.9 inch 6th Gen"
            case "iPad14,8", "iPad14,9":
                return "iPad Air 6th Gen"
            case "iPad14,10", "iPad14,11":
                return "iPad Air 7th Gen"
            case "iPad16,1":
                return "iPad mini 7th Gen (WiFi)"
            case "iPad16,2":
                return "iPad mini 7th Gen (WiFi+Cellular)"
            case "iPad16,3", "iPad16,4":
                return "iPad Pro 11 inch 5th Gen"
            case "iPad16,5", "iPad16,6":
                return "iPad Pro 12.9 inch 7th Gen"
            case "x86_64", "arm64":
                return "iOS Simulator"
            default:
                return modelIdentifier
            }
        }
    }
#endif
