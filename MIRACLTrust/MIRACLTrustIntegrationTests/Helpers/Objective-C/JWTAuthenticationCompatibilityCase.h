#import <Foundation/Foundation.h>

@interface JWTAuthenticationCompatibilityCase : NSObject

@property (nonatomic,strong) NSString *pinCode;
-(NSDictionary *)authenticate:(User *)user;
@end
