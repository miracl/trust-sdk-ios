#import <Foundation/Foundation.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface QuickCodeCompatibilityCode : NSObject

@property (nonatomic,strong) NSString *pinCode;
-(NSDictionary *)generateQuickCodeFor:(User *)user;

@end
