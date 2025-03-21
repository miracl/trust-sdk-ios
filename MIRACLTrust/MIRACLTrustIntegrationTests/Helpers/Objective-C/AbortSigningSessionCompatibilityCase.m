
#import "AbortSigningSessionCompatibilityCase.h"
#import <MIRACLTrust/MIRACLTrust-Swift.h>
#import "XCTest/XCTest.h"

@implementation AbortSigningSessionCompatibilityCase

-(NSDictionary *) abortSigningSession:(SigningSessionDetails *) sessionDetails
{
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Wait for aborting signing session"];
    
    __block BOOL returnedAbortResult = NO;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] abortSigningSession: sessionDetails completionHandler:^(BOOL aborted, NSError * _Nullable error) {
        returnedAbortResult = aborted;
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

@end
