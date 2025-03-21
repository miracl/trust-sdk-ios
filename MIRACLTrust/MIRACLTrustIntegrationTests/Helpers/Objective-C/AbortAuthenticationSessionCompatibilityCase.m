#import "AbortAuthenticationSessionCompatibilityCase.h"
#import <MIRACLTrust/MIRACLTrust-Swift.h>
#import "XCTest/XCTest.h"

@implementation AbortAuthenticationSessionCompatibilityCase
-(NSDictionary *) abortAuthenticationSession:(AuthenticationSessionDetails *) sessionDetails {
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Wait for Authentication Session abortion"];
    
    __block BOOL returnedAbortResult = NO;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] abortAuthenticationSession:sessionDetails completionHandler:^(BOOL aborted, NSError * _Nullable error) {
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
