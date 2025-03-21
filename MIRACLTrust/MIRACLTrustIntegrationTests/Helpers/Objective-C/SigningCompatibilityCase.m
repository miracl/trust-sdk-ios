#import "SigningCompatibilityCase.h"
#import <XCTest/XCTest.h>

@implementation SigningCompatibilityCase

-(NSDictionary *)signWithMessage:(NSData *)message
                       timestamp:(NSDate *)timestamp
                     signingUser:(User *)user
           signingSessionDetails:(SigningSessionDetails *) signingSessionDetails
{
    XCTestExpectation *waitForUser =
        [[XCTestExpectation alloc] initWithDescription:@"Wait for signing user registration"];
    
    __block SigningResult *returnedSignature;
    __block NSError *returnedError;
    
    if (signingSessionDetails != nil) {
        [[MIRACLTrust getInstance] _signWithMessage:message
                                               user:user
                              signingSessionDetails:signingSessionDetails
                        didRequestSigningPinHandler:^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
            pinProcessor(self.signingPinCode);
        } completionHandler:^(SigningResult * _Nullable signature, NSError * _Nullable error) {
            returnedSignature = signature;
            returnedError = error;
            [waitForUser fulfill];
        }];
    } else {
        [[MIRACLTrust getInstance] signWithMessage:message
                                               user:user
                        didRequestSigningPinHandler:^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
            pinProcessor(self.signingPinCode);
        } completionHandler:^(SigningResult * _Nullable signature, NSError * _Nullable error) {
            returnedSignature = signature;
            returnedError = error;
            [waitForUser fulfill];
        }];
    }
    
    XCTWaiterResult result =  [XCTWaiter waitForExpectations:@[waitForUser]
                                                      timeout:10.0];
    if (result != XCTWaiterResultCompleted) {
        return nil;
    }
    
    return @{
        @"signature": returnedSignature != nil ? returnedSignature : [NSNull null] ,
        @"error": returnedError != nil ? returnedError : [NSNull null]
    };
}

@end
