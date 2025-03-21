#import <XCTest/XCTest.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>
#import "JWTAuthenticationCompatibilityCase.h"

@implementation JWTAuthenticationCompatibilityCase

-(NSDictionary *)authenticate:(User *)user
{
    XCTestExpectation *waitForJWT = [[XCTestExpectation alloc] initWithDescription:@"Wait for JWT generation"];
    __block NSString* returnedJWT;
    __block NSError* returnedError;
    
    [[MIRACLTrust getInstance] authenticateWithUser:user
                                   didRequestPinHandler:^(void (^ _Nonnull pinHandler)(NSString * _Nullable)) {
        pinHandler(self.pinCode);
    } completionHandler:^(NSString * _Nullable jwt, NSError * _Nullable error) {
        returnedJWT = jwt;
        returnedError = error;
        [waitForJWT fulfill];
    }];
    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[waitForJWT]
                                                      timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"jwt" : returnedJWT != nil ? returnedJWT : [NSNull null],
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}

@end
