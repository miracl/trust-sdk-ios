
Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '11.0'
  s.name = "MIRACLTrust"
  s.summary = "MIRACL Trust SDK for iOS"
  s.requires_arc = true
  s.version = "1.9.0"
  s.license = { :type => "Apache2", :file => "LICENSE" }
  s.author = { "MIRACL" => "operations@miracl.com" }
  s.homepage = "https://github.com/miracl/trust-sdk-ios"
  s.source = {
    :git => "https://github.com/miracl/trust-sdk-ios",
    :tag => "1.9.0"
  }

  s.framework = "UIKit"
  s.source_files =
    "MIRACLTrust/MIRACLTrust-Sources/**/*.{h,swift,c}",
    "MIRACLTrust/MIRACLTrust-iOS/**/*.{h,swift,c}"

  s.module_map = "MIRACLTrust/MIRACLTrust-Sources/MIRACLTrust.modulemap"
  s.compiler_flags = "-w",
  "-DNDEBUG",
  "-DSQLITE_HAS_CODEC",
  "-DSQLITE_TEMP_STORE=2",
  "-DSQLITE_SOUNDEX",
  "-DSQLITE_THREADSAFE",
  "-DSQLITE_ENABLE_RTREE",
  "-DSQLITE_ENABLE_STAT3",
  "-DSQLITE_ENABLE_STAT4",
  "-DSQLITE_ENABLE_COLUMN_METADATA",
  "-DSQLITE_ENABLE_MEMORY_MANAGEMENT",
  "-DSQLITE_ENABLE_LOAD_EXTENSION",
  "-DSQLITE_ENABLE_FTS4",
  "-DSQLITE_ENABLE_FTS4_UNICODE61",
  "-DSQLITE_ENABLE_FTS3_PARENTHESIS",
  "-DSQLITE_ENABLE_UNLOCK_NOTIFY",
  "-DSQLITE_ENABLE_JSON1",
  "-DSQLITE_ENABLE_FTS5",
  "-DSQLCIPHER_CRYPTO_CC",
  "-DHAVE_USLEEP=1",
  "-DSQLITE_MAX_VARIABLE_NUMBER=99999"
  s.pod_target_xcconfig = {
    "HEADER_SEARCH_PATHS" => "$(PODS_ROOT)/SQLCipher",
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) SQLITE_HAS_CODEC=1",
    "OTHER_CFLAGS" => "$(inherited) -DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=2 -DSQLITE_SOUNDEX -DSQLITE_THREADSAFE -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_STAT3 -DSQLITE_ENABLE_STAT4 -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_MEMORY_MANAGEMENT -DSQLITE_ENABLE_LOAD_EXTENSION -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_FTS4_UNICODE61 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_UNLOCK_NOTIFY -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_FTS5 -DSQLCIPHER_CRYPTO_CC -DHAVE_USLEEP=1 -DSQLITE_MAX_VARIABLE_NUMBER=99999"
  }

  s.frameworks = "Foundation","Security"
  s.vendored_frameworks = 'MIRACLTrust/MIRACLTrust-Sources/Crypto/src/*.xcframework'
  s.swift_version = "5.1"
  s.info_plist = { "MIRACL_SDK_VERSION" => "#{s.version}"}
end
