#import <XCTest/XCTest.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface QRAuthenticationCompatibilityCase : NSObject
@property (nonatomic,strong) NSString *pinCode;
-(NSDictionary *)authenticateUser:(User *)user
                           qrCode:(NSString *)qrCode;
@end
