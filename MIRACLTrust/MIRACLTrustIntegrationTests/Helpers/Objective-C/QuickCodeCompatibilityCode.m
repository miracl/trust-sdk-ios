#import <XCTest/XCTest.h>
#import "QuickCodeCompatibilityCode.h"

@implementation QuickCodeCompatibilityCode

-(NSDictionary *)generateQuickCodeFor:(User *)user
{
    XCTestExpectation *waitForQuickCode = [[XCTestExpectation alloc] initWithDescription:@"Wait for QuickCode generation"];
    __block QuickCode* returnedQuickCode;
    __block NSError* returnedError;
    
    [[MIRACLTrust getInstance] generateQuickCodeWithUser:user
                                      didRequestPinHandler:^(void (^ _Nonnull pinHandler)(NSString * _Nullable)) {
        pinHandler(self.pinCode);
    } completionHandler:^(QuickCode * _Nullable quickCode, NSError * _Nullable error) {
        returnedQuickCode = quickCode;
        returnedError = error;
        [waitForQuickCode fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[waitForQuickCode]
                                                      timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        return nil;
    }
    
    return @{
        @"quickCode" : returnedQuickCode,
        @"error" : returnedError != nil ? returnedError : [NSNull null]
    };
}

@end
