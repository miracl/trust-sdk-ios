#This script fixes issues related with generation of swiftinterface files, which uses Private modules.

cd MIRACLTrust
#Remove MIRACLTrust from swiftinterface file.
find . -name "*.swiftinterface" -exec sed -i -e 's/MIRACLTrust\.//g' {} \;

# Fix imports into the simulator part
MODULE_DIR="xcframework-output/MIRACLTrust.xcframework/ios-arm64_x86_64-simulator/MIRACLTrust.framework/Modules/MIRACLTrust.swiftmodule"

sed -i.tmp 's/import Crypto/import MIRACLTrust.Crypto/' $MODULE_DIR/arm64-apple-ios-simulator.private.swiftinterface
sed -i.tmp 's/import SQLChiper/import MIRACLTrust.SQLChiper/' $MODULE_DIR/arm64-apple-ios-simulator.private.swiftinterface
rm -rf $MODULE_DIR/arm64-apple-ios-simulator.private.swiftinterface.tmp

sed -i.tmp 's/import Crypto/import MIRACLTrust.Crypto/' $MODULE_DIR/arm64-apple-ios-simulator.swiftinterface
sed -i.tmp 's/import SQLChiper/import MIRACLTrust.SQLChiper/' $MODULE_DIR/arm64-apple-ios-simulator.swiftinterface
rm -rf $MODULE_DIR/arm64-apple-ios-simulator.swiftinterface.tmp

sed -i.tmp 's/import Crypto/import MIRACLTrust.Crypto/' $MODULE_DIR/x86_64-apple-ios-simulator.private.swiftinterface
sed -i.tmp 's/import SQLChiper/import MIRACLTrust.SQLChiper/' $MODULE_DIR/x86_64-apple-ios-simulator.private.swiftinterface
rm -rf $MODULE_DIR/x86_64-apple-ios-simulator.private.swiftinterface.tmp

sed -i.tmp 's/import Crypto/import MIRACLTrust.Crypto/' $MODULE_DIR/x86_64-apple-ios-simulator.swiftinterface
sed -i.tmp 's/import SQLChiper/import MIRACLTrust.SQLChiper/' $MODULE_DIR/x86_64-apple-ios-simulator.swiftinterface
rm -rf $MODULE_DIR/x86_64-apple-ios-simulator.swiftinterface.tmp

# Fix imports into the device part

MODULE_DIR="xcframework-output/MIRACLTrust.xcframework/ios-arm64/MIRACLTrust.framework/Modules/MIRACLTrust.swiftmodule"

sed -i.tmp 's/import Crypto/import MIRACLTrust.Crypto/' $MODULE_DIR/arm64-apple-ios.private.swiftinterface
sed -i.tmp 's/import SQLChiper/import MIRACLTrust.SQLChiper/' $MODULE_DIR/arm64-apple-ios.private.swiftinterface
rm -rf $MODULE_DIR/arm64-apple-ios.private.swiftinterface.tmp

sed -i.tmp 's/import Crypto/import MIRACLTrust.Crypto/' $MODULE_DIR/arm64-apple-ios.swiftinterface
sed -i.tmp 's/import SQLChiper/import MIRACLTrust.SQLChiper/' $MODULE_DIR/arm64-apple-ios.swiftinterface
rm -rf $MODULE_DIR/arm64-apple-ios.swiftinterface.tmp
