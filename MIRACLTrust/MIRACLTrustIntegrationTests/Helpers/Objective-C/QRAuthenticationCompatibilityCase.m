#import "QRAuthenticationCompatibilityCase.h"

@implementation QRAuthenticationCompatibilityCase

-(NSDictionary *)authenticateUser:(User *)user
                           qrCode:(NSString *)qrCode
{
    XCTestExpectation *waitForAuthentication= [[XCTestExpectation alloc] initWithDescription:@"Wait for user registration"];
    __block BOOL authenticationResult = NO;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] authenticateWithUser:user qrCode:qrCode didRequestPinHandler:^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
        pinProcessor(self.pinCode);
    } completionHandler:^(BOOL isAuthenticated, NSError * _Nullable error) {
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
