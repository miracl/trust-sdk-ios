#import <XCTest/XCTest.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>

@interface CrossDeviceSessionCompatiblityCase : XCTest

- (NSDictionary *) getCrossDeviceSessionForQRCode:(NSString *)qrCode;
- (NSDictionary *) getCrossDeviceSessionForUniversalLinkURL:(NSURL *)universalLinkURL;
- (NSDictionary *) getCrossDeviceSessionForPushNotificationsPayload:(NSDictionary *)pushNotificationsPayload;
- (NSDictionary *) abortCrossDeviceSession:(CrossDeviceSession *) crossDeviceSession;
- (NSDictionary *) authenticateCrossDeviceSession:(CrossDeviceSession *)crossDeviceSession
                                             user:(User *) user
                                           andPin:(NSString *)pinCode;
-(NSDictionary *)signCrossDeviceSession:(CrossDeviceSession *) crossDeviceSession
                                signingUser:(User *)user
                                 andPinCode:(NSString *) pinCode;
@end
