#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface UniversalLinkAuthenticationCompatibilityCase : NSObject
@property (nonatomic,strong) NSString *pinCode;
-(NSDictionary *)authenticateUser:(User *)user
                 universalLinkURL:(NSURL *)url;
@end

