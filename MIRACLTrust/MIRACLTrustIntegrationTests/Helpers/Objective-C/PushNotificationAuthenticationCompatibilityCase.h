#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface PushNotificationAuthenticationCompatibilityCase : NSObject

@property (nonatomic,strong) NSString *pinCode;
-(NSDictionary *)authenticateWithPayload:(NSDictionary *)payload;

@end
