#import "CrossDeviceSessionCompatiblityCase.h"
#import "MIRACLTrust/MIRACLTrust_iOS.h"

@implementation CrossDeviceSessionCompatiblityCase

- (NSDictionary *) getCrossDeviceSessionForQRCode:(NSString *)qrCode
{
    XCTestExpectation *waitForActivationToken = [[XCTestExpectation alloc] initWithDescription:@"Wait for Cross device Session"];
    __block CrossDeviceSession* returnedCrossDeviceSession;
    __block NSError* returnedError;
    
    [[MIRACLTrust getInstance]
     getCrossDeviceSessionFromQRCode:qrCode
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
     getCrossDeviceSessionFromUniversalLinkURL: universalLinkURL
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
     getCrossDeviceSessionFromPushNotificationPayload: pushNotificationsPayload
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

    [[MIRACLTrust getInstance] abortCrossDeviceSession:crossDeviceSession completionHandler:^(BOOL result, NSError * error) {
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

- (NSDictionary *) authenticateCrossDeviceSession:(CrossDeviceSession *)crossDeviceSession
                                             user:(User *) user
                                           andPin:(NSString *)pinCode
{
    XCTestExpectation *waitForAuthentication= [[XCTestExpectation alloc] initWithDescription:@"Wait for cross device session authentication"];
    __block BOOL authenticationResult = NO;
    __block NSError *returnedError;
    [[MIRACLTrust getInstance]
        authenticateCrossDeviceSession:crossDeviceSession
        user:user
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

-(NSDictionary *)signCrossDeviceSession: (CrossDeviceSession *) crossDeviceSession
                                signingUser: (User *)user
                                 andPinCode: (NSString *) pinCode
{
    XCTestExpectation *waitForSigningWithSession =
        [[XCTestExpectation alloc] initWithDescription:@"Wait for signing with cross device session"];
    
    __block BOOL returnedIsSigned = NO;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] signCrossDeviceSession:crossDeviceSession
                                                 user:user
                          didRequestSigningPinHandler:^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
        pinProcessor(pinCode);
    } completionHandler:^(BOOL isSigned, NSError * _Nullable error) {
        returnedIsSigned = isSigned;
        returnedError = error;
        [waitForSigningWithSession fulfill];
    }];
    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[waitForSigningWithSession]
                                                      timeout:10.0];
    if (result != XCTWaiterResultCompleted) {
        return nil;
    }
    
    return @{
        @"isSigned": @(returnedIsSigned) ,
        @"error": returnedError != nil ? returnedError : [NSNull null]
    };
}


@end
