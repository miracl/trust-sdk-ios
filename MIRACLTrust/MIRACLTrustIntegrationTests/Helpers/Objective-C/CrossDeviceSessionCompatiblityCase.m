#import "CrossDeviceSessionCompatiblityCase.h"
#import "MIRACLTrust/MIRACLTrust_iOS.h"

@implementation CrossDeviceSessionCompatiblityCase

- (NSDictionary *) getCrossDeviceSessionForQRCode:(NSString *)qrCode
{
    XCTestExpectation *waitForActivationToken = [[XCTestExpectation alloc] initWithDescription:@"Wait for Cross device Session"];
    __block CrossDeviceSession* returnedCrossDeviceSession;
    __block NSError* returnedError;
    
    [[MIRACLTrust getInstance]
     _getCrossDeviceSessionFromQRCodeWithQrCode:qrCode
     completionHandler:^(CrossDeviceSession * session, NSError * error) {
        returnedCrossDeviceSession = session;
        returnedError = error;
        [waitForActivationToken fulfill];
    }];

    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[waitForActivationToken]
                                                    timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"crossDeviceSession" : returnedCrossDeviceSession != nil ? returnedCrossDeviceSession : [NSNull null],
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}

- (NSDictionary *) getCrossDeviceSessionForUniversalLinkURL:(NSURL *)universalLinkURL
{
    XCTestExpectation *waitForActivationToken = [[XCTestExpectation alloc] initWithDescription:@"Wait for Cross device Session"];
    __block CrossDeviceSession* returnedCrossDeviceSession;
    __block NSError* returnedError;
    
    [[MIRACLTrust getInstance]
     _getCrossDeviceSessionFromUniversalLinkURLWithUniversalLinkURL: universalLinkURL
     completionHandler:^(CrossDeviceSession * session, NSError * error) {
        returnedCrossDeviceSession = session;
        returnedError = error;
        [waitForActivationToken fulfill];
    }];

    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[waitForActivationToken]
                                                    timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"crossDeviceSession" : returnedCrossDeviceSession != nil ? returnedCrossDeviceSession : [NSNull null],
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}

- (NSDictionary *) getCrossDeviceSessionForPushNotificationsPayload:(NSDictionary *)pushNotificationsPayload
{
    XCTestExpectation *waitForActivationToken = [[XCTestExpectation alloc] initWithDescription:@"Wait for Cross device Session"];
    __block CrossDeviceSession* returnedCrossDeviceSession;
    __block NSError* returnedError;
    
    [[MIRACLTrust getInstance]
     _getCrossDeviceSessionFromPushNotificationPayloadWithPushNotificationPayload: pushNotificationsPayload
     completionHandler:^(CrossDeviceSession * session, NSError * error) {
        returnedCrossDeviceSession = session;
        returnedError = error;
        [waitForActivationToken fulfill];
    }];

    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[waitForActivationToken]
                                                    timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"crossDeviceSession" : returnedCrossDeviceSession != nil ? returnedCrossDeviceSession : [NSNull null],
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}

- (NSDictionary *) abortCrossDeviceSession:(CrossDeviceSession *) crossDeviceSession
{
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Wait for Cross Device Session abortion"];
    
    __block BOOL returnedAbortResult = NO;
    __block NSError *returnedError;

    [[MIRACLTrust getInstance] _abortCrossDeviceSession:crossDeviceSession completionHandler:^(BOOL result, NSError * error) {
        returnedAbortResult = result;
        returnedError = error;
        [expectation fulfill];
    }];
    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[expectation]
                                                     timeout:10.0];
    if(result != XCTWaiterResultCompleted){
        return nil;
    }
    
    return @{
        @"isAborted" : @(returnedAbortResult),
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}

- (NSDictionary *) authenticateWithUser:(User *)user
                     crossDeviceSession:(CrossDeviceSession *)crossDeviceSession
                                 andPin:(NSString *)pinCode
{
    XCTestExpectation *waitForAuthentication= [[XCTestExpectation alloc] initWithDescription:@"Wait for cross device session authentication"];
    __block BOOL authenticationResult = NO;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance]
        _authenticateWithUser:user
          crossDeviceSession:crossDeviceSession
        didRequestPinHandler:^(void (^ pinProcessor)(NSString *)) {
        pinProcessor(pinCode);
    } completionHandler:^(BOOL isAuthenticated, NSError * error) {
        authenticationResult = isAuthenticated;
        returnedError = error;
        [waitForAuthentication fulfill];
    }];
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[waitForAuthentication]
                                                      timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"isAuthenticated" : @(authenticationResult),
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}


@end
