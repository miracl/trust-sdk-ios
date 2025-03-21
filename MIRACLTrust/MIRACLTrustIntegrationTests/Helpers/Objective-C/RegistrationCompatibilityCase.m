#import "RegistrationCompatibilityCase.h"

@implementation RegistrationCompatibilityCase

-(NSDictionary *)registerUserWithId:(NSString *)userid
                    activationToken:(NSString *)activationToken
{
    XCTestExpectation *waitForUser = [[XCTestExpectation alloc] initWithDescription:@"Wait for user registration"];
    __block User *returnedUser;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] registerFor:userid
                           activationToken:activationToken
                    pushNotificationsToken:nil
                      didRequestPinHandler:^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
        pinProcessor(self.pinCode);
    } completionHandler:^(User * _Nullable user, NSError * _Nullable error) {
        returnedUser = user;
        returnedError = error;
        [waitForUser fulfill];
    }];
    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[waitForUser]
                                                      timeout:10.0];
    if(result != XCTWaiterResultCompleted){
        return nil;
    }
    
    return  @{ @"user" : returnedUser != nil ? returnedUser : [NSNull null] ,
               @"error" : returnedError != nil ? returnedError : [NSNull null] };
}

@end
