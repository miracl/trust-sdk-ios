#import <XCTest/XCTest.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface CrossDeviceSessionCompatiblityCase : XCTest

- (NSDictionary *) getCrossDeviceSessionForQRCode:(NSString *)qrCode;
- (NSDictionary *) getCrossDeviceSessionForUniversalLinkURL:(NSURL *)universalLinkURL;
- (NSDictionary *) getCrossDeviceSessionForPushNotificationsPayload:(NSDictionary *)pushNotificationsPayload;
- (NSDictionary *) abortCrossDeviceSession:(CrossDeviceSession *) crossDeviceSession;
- (NSDictionary *) authenticateWithUser:(User *)user
                     crossDeviceSession:(CrossDeviceSession *)crossDeviceSession
                                 andPin:(NSString *)pinCode;
@end
