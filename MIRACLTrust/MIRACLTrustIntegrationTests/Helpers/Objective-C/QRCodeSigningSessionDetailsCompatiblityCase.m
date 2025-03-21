#import <XCTest/XCTest.h>
#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <MIRACLTrust/MIRACLTrust_iOS.h>
#import "QRCodeSigningSessionDetailsCompatiblityCase.h"

@implementation QRCodeSigningSessionDetailsCompatiblityCase

-(NSDictionary *) getSiginingSessionDetails:(NSString *)qrCode
{
    XCTestExpectation *waitForAuthentication= [[XCTestExpectation alloc] initWithDescription:@"Wait for user registration"];
    __block SigningSessionDetails *returnedSessionDetails;
    __block NSError *returnedError;
    
    [[MIRACLTrust getInstance] getSigningSessionDetailsFromQRcode:qrCode completionHandler:^(SigningSessionDetails * _Nullable signingSessionDetails, NSError * _Nullable error) {
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
