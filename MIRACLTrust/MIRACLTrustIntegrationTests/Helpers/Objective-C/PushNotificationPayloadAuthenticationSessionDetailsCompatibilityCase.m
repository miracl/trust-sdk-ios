#import "MIRACLTrust/MIRACLTrust-Swift.h"
#import <XCTest/XCTest.h>
#import "PushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase.h"

@implementation PushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase
-(NSDictionary *)getAuthenticationSessionDetailsFromPushNotificationPayload:(NSDictionary *) payload
{
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"getAuthenticationSessionDetailsFromQRCode"];
    
    __block AuthenticationSessionDetails *returnedSessionDetails;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] getAuthenticationSessionDetailsFromPushNotificationPayload:payload completionHandler:^(AuthenticationSessionDetails * _Nullable sessionDetails, NSError * _Nullable error) {
        returnedSessionDetails = sessionDetails;
        returnedError = error;
        
        [expectation fulfill];
    }];

    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[expectation]
                                                      timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"authenticationSessionDetails" : returnedSessionDetails != nil ? returnedSessionDetails : [NSNull null] ,
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}

@end
