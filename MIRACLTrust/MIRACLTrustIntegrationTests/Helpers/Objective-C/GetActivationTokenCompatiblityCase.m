#import "GetActivationTokenCompatiblityCase.h"

@implementation GetActivationTokenCompatiblityCase
- (NSDictionary *)getActivationTokenFrom: (NSURL *)verificationURL {
    XCTestExpectation *waitForActivationToken = [[XCTestExpectation alloc] initWithDescription:@"Wait for Activation Toke"];
    __block NSString* returnedActivationToken;
    __block NSError* returnedError;
    
    [[MIRACLTrust getInstance] getActivationTokenWithVerificationURL:verificationURL completionHandler:^(ActivationTokenResponse * _Nullable response, NSError * _Nullable error) {
        returnedActivationToken = response.activationToken;
        returnedError = error;
        [waitForActivationToken fulfill];
    }];
    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[waitForActivationToken]
                                                      timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"activationToken" : returnedActivationToken != nil ? returnedActivationToken : [NSNull null],
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}
@end
