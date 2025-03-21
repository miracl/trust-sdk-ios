// swift-tools-version: 5.7

import PackageDescription

let sqliteSettings: [CSetting] = [
    .define("NDEBUG"),
    .define("SQLITE_HAS_CODEC"),
    .define("SQLITE_TEMP_STORE", to: "2"),
    .define("SQLITE_SOUNDEX"),
    .define("SQLITE_THREADSAFE"),
    .define("SQLITE_ENABLE_RTREE"),
    .define("SQLITE_ENABLE_STAT3"),
    .define("SQLITE_ENABLE_STAT4"),
    .define("SQLITE_ENABLE_COLUMN_METADATA"),
    .define("SQLITE_ENABLE_MEMORY_MANAGEMENT"),
    .define("SQLITE_ENABLE_LOAD_EXTENSION"),
    .define("SQLITE_ENABLE_FTS4"),
    .define("SQLITE_ENABLE_FTS4_UNICODE61"),
    .define("SQLITE_ENABLE_FTS3_PARENTHESIS"),
    .define("SQLITE_ENABLE_UNLOCK_NOTIFY"),
    .define("SQLITE_ENABLE_JSON1"),
    .define("SQLITE_ENABLE_FTS5"),
    .define("SQLCIPHER_CRYPTO_CC"),
    .define("HAVE_USLEEP", to: "1"),
    .define("SQLITE_MAX_VARIABLE_NUMBER", to: "99999")
]

let package = Package(
    name: "MIRACLTrust",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "MIRACLTrust",
            targets: [
                "MIRACLTrust"
            ]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MIRACLTrust",
            dependencies: ["CryptoSPM", "SQLChiper"],
            path: "MIRACLTrust/MIRACLTrust-Sources",
            exclude: [
                "MIRACLTrust.modulemap",
                "Crypto/include",
                "Crypto/src",
                "Crypto/bridge.c",
                "User Storage/SQLChiper"
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            cSettings: sqliteSettings
        ),

        .target(
            name: "CryptoSPM",
            dependencies: [
                "libamcl_core",
                "libamcl_curve_BN254CX",
                "libamcl_mpin_BN254CX",
                "libamcl_pairing_BN254CX"
            ],
            path: "MIRACLTrust/MIRACLTrust-Sources/Crypto",
            exclude: ["Crypto.swift", "CryptoError.swift", "CryptoBlueprint.swift", "src"]
        ),

        .target(
            name: "SQLChiper",
            path: "MIRACLTrust/MIRACLTrust-Sources/User Storage/SQLChiper",
            cSettings: sqliteSettings
        ),

        .binaryTarget(name: "libamcl_core", path: "MIRACLTrust/MIRACLTrust-Sources/Crypto/src/libamcl_core.xcframework"),
        .binaryTarget(name: "libamcl_curve_BN254CX", path: "MIRACLTrust/MIRACLTrust-Sources/Crypto/src/libamcl_curve_BN254CX.xcframework"),
        .binaryTarget(name: "libamcl_mpin_BN254CX", path: "MIRACLTrust/MIRACLTrust-Sources/Crypto/src/libamcl_mpin_BN254CX.xcframework"),
        .binaryTarget(name: "libamcl_pairing_BN254CX", path: "MIRACLTrust/MIRACLTrust-Sources/Crypto/src/libamcl_pairing_BN254CX.xcframework")
    ]
)
