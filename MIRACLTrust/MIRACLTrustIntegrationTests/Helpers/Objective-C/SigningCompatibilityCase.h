#import <Foundation/Foundation.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface SigningCompatibilityCase : NSObject

@property (nonatomic,strong) NSString *signingPinCode;

-(NSDictionary *)signWithMessage:(NSData *)message
                       timestamp:(NSDate *)timestamp
                     signingUser:(User *)user
           signingSessionDetails:(SigningSessionDetails *) signingSessionDetails;

@end

