#import "UniversalLinkURLSigningSessionDetailsCompatiblityCase.h"
#import "MIRACLTrust/MIRACLTrust-Swift.h"
#import <XCTest/XCTest.h>

@implementation UniversalLinkURLSigningSessionDetailsCompatiblityCase

-(NSDictionary *) getSiginingSessionDetails:(NSURL *)universalLinkURL
{
    XCTestExpectation *waitForAuthentication= [[XCTestExpectation alloc] initWithDescription:@"Wait for user registration"];
    __block SigningSessionDetails *returnedSessionDetails;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] getSigningSessionDetailsFromUniversalLinkURL:universalLinkURL completionHandler:^(SigningSessionDetails * _Nullable signingSessionDetails, NSError * _Nullable error) {
        returnedSessionDetails = signingSessionDetails;
        returnedError = error;
        [waitForAuthentication fulfill];
    }];
    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[waitForAuthentication]
                                                      timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"signingSessionDetails" : returnedSessionDetails != nil ? returnedSessionDetails : [NSNull null],
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}


@end
