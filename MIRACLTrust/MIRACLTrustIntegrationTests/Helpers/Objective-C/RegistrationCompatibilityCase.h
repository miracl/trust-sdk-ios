
#import <XCTest/XCTest.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface RegistrationCompatibilityCase : NSObject

@property (nonatomic,strong) NSString *pinCode;

-(NSDictionary *)registerUserWithId:(NSString *)userid
                    activationToken:(NSString *)activationToken;
@end

