#import <Foundation/Foundation.h>

@interface QRCodeAuthenticationSessionDetailsCompatiblityCase : NSObject
-(NSDictionary *)getAuthenticationSessionDetailsFromQRCode:(NSString *)qrCode;
@end
