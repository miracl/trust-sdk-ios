#import <XCTest/XCTest.h>
#import "QRAuthenticationCompatibilityCase.h"
#import "RegistrationCompatibilityCase.h"
#import "SigningCompatibilityCase.h"
#import "JWTAuthenticationCompatibilityCase.h"
#import "QuickCodeCompatibilityCode.h"
#import "UniversalLinkAuthenticationCompatibilityCase.h"
#import "PushNotificationAuthenticationCompatibilityCase.h"
#import "QRCodeAuthenticationSessionDetailsCompatiblityCase.h"
#import "UniversalLinkURLAuthenticationSessionDetailsCompatiblityCase.h"
#import "PushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase.h"
#import "AbortAuthenticationSessionCompatibilityCase.h"
#import "GetActivationTokenCompatiblityCase.h"
#import "CrossDeviceSessionCompatiblityCase.h"
#import <MIRACLTrustIntegrationTests-Swift.h>
#import <CommonCrypto/CommonCrypto.h>

@interface MIRACLTrustCompatibilityTests : XCTestCase
@property (nonatomic,strong) QRAuthenticationCompatibilityCase *authentication;
@property (nonatomic,strong) RegistrationCompatibilityCase *registration;
@property (nonatomic,strong) SigningCompatibilityCase *signing;
@property (nonatomic,strong) QuickCodeCompatibilityCode *quickCode;
@property (nonatomic,strong) JWTAuthenticationCompatibilityCase *jwtAuthentication;
@property (nonatomic,strong) UniversalLinkAuthenticationCompatibilityCase *universalLinkAuthentication;
@property (nonatomic,strong) PushNotificationAuthenticationCompatibilityCase *pushNotificationAuthentication;
@property (nonatomic, strong) QRCodeAuthenticationSessionDetailsCompatiblityCase *qrCodeAuthenticationSessionDetailsCompatiblityCase;
@property (nonatomic, strong) UniversalLinkURLAuthenticationSessionDetailsCompatiblityCase *universalLinkURLAuthenticationSessionDetailsCompatiblityCase;
@property (nonatomic, strong) PushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase *pushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase;
@property (nonatomic, strong) AbortAuthenticationSessionCompatibilityCase *abortAuthenticationSessionCompatibilityCase;
@property (nonatomic, strong) GetActivationTokenCompatiblityCase *getActivationTokenCompatiblityCase;
@property (nonatomic, strong) CrossDeviceSessionCompatiblityCase *getCrossDeviceSessionCompatibilityCase;

@property (nonatomic,strong) Configuration *configuration;
@property (nonatomic,strong) StartSessionResult *session;
@property (nonatomic,strong) NSString *activationToken;
@property (nonatomic,strong) NSString *randomNumber;

@property (nonatomic,strong) PlatformAPIWrapper *api;
@property (nonatomic,strong) NSString *userId;
@property (nonatomic,strong) NSString *qrCodeURL;
@property (nonatomic,strong) NSString *projectId;
@property (nonatomic,strong) CrossDeviceSession *crossDeviceSession;

@end

@implementation MIRACLTrustCompatibilityTests

- (void)setUp
{
    [super setUp];
    self.randomNumber = [self randomNumberAsString];

    self.registration = [[RegistrationCompatibilityCase alloc] init];
    self.registration.pinCode = self.randomNumber;
    
    self.authentication = [[QRAuthenticationCompatibilityCase alloc] init];
    self.authentication.pinCode = self.randomNumber;
    
    self.signing = [[SigningCompatibilityCase alloc] init];
    self.signing.signingPinCode = self.randomNumber;
    
    self.jwtAuthentication = [[JWTAuthenticationCompatibilityCase alloc] init];
    self.jwtAuthentication.pinCode = self.randomNumber;
    
    self.universalLinkAuthentication = [[UniversalLinkAuthenticationCompatibilityCase alloc] init];
    self.universalLinkAuthentication.pinCode = self.randomNumber;
    
    self.pushNotificationAuthentication = [[PushNotificationAuthenticationCompatibilityCase alloc] init];
    self.pushNotificationAuthentication.pinCode = self.randomNumber;
    
    self.quickCode = [[QuickCodeCompatibilityCode alloc] init];
    self.quickCode.pinCode = self.randomNumber;
    
    self.qrCodeAuthenticationSessionDetailsCompatiblityCase = [[QRCodeAuthenticationSessionDetailsCompatiblityCase alloc] init];
    self.universalLinkURLAuthenticationSessionDetailsCompatiblityCase = [[UniversalLinkURLAuthenticationSessionDetailsCompatiblityCase alloc] init];
    self.pushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase = [[PushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase alloc] init];
    self.abortAuthenticationSessionCompatibilityCase = [[AbortAuthenticationSessionCompatibilityCase alloc] init];
    self.getActivationTokenCompatiblityCase = [[GetActivationTokenCompatiblityCase alloc] init];
    self.getCrossDeviceSessionCompatibilityCase = [[CrossDeviceSessionCompatiblityCase alloc] init];
}

- (void)testVerificationConfirmationError
{
    NSString *projectId = NSProcessInfo.processInfo.environment[@"projectIdCUV"];
    NSString *serviceAccountToken = NSProcessInfo.processInfo.environment[@"serviceAccountTokenCUV"];
    NSString *projectURL = NSProcessInfo.processInfo.environment[@"projectURLCUV"];

    NSString *deviceName = [[NSUUID UUID] UUIDString];

    ConfigurationBuilder *builder = [
        [ConfigurationBuilder alloc]
        initWithProjectId:projectId
        projectURL:projectURL
        deviceName:deviceName];
    
    NSError *error;
    Configuration *configuration = [builder buildAndReturnError:&error];
    
    [MIRACLTrust configureWith:configuration error:&error];
    if (error != nil) {
        XCTFail(@"Configuration failed");
        return;
    }
    
    
    self.userId = @"int@miracl.com";
    self.api = [[PlatformAPIWrapper alloc] init];
    self.session = [self.api startSessionWithProjectId:projectId
                                            projectURL:projectURL
                                                userId:nil
                                                  hash:nil
                                           description:nil];
  
    NSNumber *expirationInSeconds = @(5);
    NSDate *expirationDate = [NSCalendar.currentCalendar
                              dateByAddingUnit:NSCalendarUnitSecond
                              value:expirationInSeconds.intValue
                              toDate:[NSDate date]
                              options: 0];
    
    NSURL *verificationURL = [self.api getVerificaitonURLWithServiceAccountToken:serviceAccountToken
                                                                       projectId:projectId
                                                                      projectURL:projectURL
                                                                          userId:self.userId
                                                                        accessId:self.session.accessId
                                                                      expiration:expirationDate];
    NSNumber *sleepTime = @(expirationInSeconds.intValue + 1);
    sleep(sleepTime.intValue);
    
    XCTestExpectation *waitForAuthentication= [[XCTestExpectation alloc] initWithDescription:@"Wait for Activation Token"];
    [[MIRACLTrust getInstance] getActivationTokenWithVerificationURL:verificationURL completionHandler:^(ActivationTokenResponse * _Nullable response, NSError * _Nullable error) {
        XCTAssertNil(response);
        XCTAssertNotNil(error);
        
        NSDictionary *errorUserInfo = error.userInfo;
        ActivationTokenErrorResponse *errorResponse = errorUserInfo[@"activationTokenErrorResponse"];
        XCTAssertEqual(error.code, 3);
        XCTAssertEqualObjects(error.domain, @"MIRACLTrust.ActivationTokenError");
        XCTAssertNotNil(errorResponse);
        XCTAssertEqualObjects(errorResponse.accessId, self.session.accessId);
        XCTAssertEqualObjects(errorResponse.userId, self.userId);
        XCTAssertEqualObjects(errorResponse.projectId, projectId);
        
        [waitForAuthentication fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[waitForAuthentication]
                                                    timeout:10.0];
    if(result != XCTWaiterResultCompleted ){
        XCTFail(@"Tests failed");
    }
}

- (void)testCompatibility
{
    NSError *error;
    
    NSString *projectId = NSProcessInfo.processInfo.environment[@"projectIdDV"];
    NSString *projectURL = NSProcessInfo.processInfo.environment[@"projectURLCUV"];
    
    NSString *deviceName = [[NSUUID UUID] UUIDString];
    ConfigurationBuilder *builder =
    [[ConfigurationBuilder alloc]
        initWithProjectId:projectId
               projectURL:projectURL
               deviceName:deviceName
    ];

    Configuration *configuration = [builder buildAndReturnError:&error];
    
    
    [MIRACLTrust configureWith:configuration
                         error:&error];
    
    if (error != nil) {
        XCTFail(@"Configuration failed");
        return;
    }
    
    projectId = NSProcessInfo.processInfo.environment[@"projectIdCUV"];
    NSString *serviceAccountToken = NSProcessInfo.processInfo.environment[@"serviceAccountTokenCUV"];
    
    error = nil;
    [[MIRACLTrust getInstance] setProjectId:projectId];
    
    if (error != nil) {
        XCTFail(@"Configuration failed");
        return;
    }
    
    self.userId = @"global@example.com";
    self.api = [[PlatformAPIWrapper alloc] init];
    self.session = [self.api startSessionWithProjectId:projectId
                                            projectURL:projectURL
                                                userId:nil
                                                  hash:nil
                                           description:nil];
    
    self.qrCodeURL = [NSString stringWithFormat:@"https://mcl.mpin.io/mobile-login/#%@",self.session.accessId];
    self.projectId = projectId;
    
    
    NSDictionary *dict = [self.qrCodeAuthenticationSessionDetailsCompatiblityCase getAuthenticationSessionDetailsFromQRCode:self.qrCodeURL];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    XCTAssertFalse([dict[@"authenticationSessionDetails"] isEqual:[NSNull null]]);
    
    NSURL *universalLinkURL = [NSURL URLWithString:self.qrCodeURL];
    dict = [self.universalLinkURLAuthenticationSessionDetailsCompatiblityCase getAuthenticationSessionDetailsFromUniversalLinkURL:universalLinkURL];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    XCTAssertFalse([dict[@"authenticationSessionDetails"] isEqual:[NSNull null]]);
    
    NSDictionary *payload = @{
        @"userID" : self.userId,
        @"qrURL" : self.qrCodeURL,
        @"projectID": self.projectId
    };
    dict = [self.pushNotificationPayloadAuthenticationSessionDetailsCompatibilityCase getAuthenticationSessionDetailsFromPushNotificationPayload:payload];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    XCTAssertFalse([dict[@"authenticationSessionDetails"] isEqual:[NSNull null]]);
    
    AuthenticationSessionDetails *sessionDetails = (AuthenticationSessionDetails *)dict[@"authenticationSessionDetails"];
    
    dict = [self.abortAuthenticationSessionCompatibilityCase abortAuthenticationSession:sessionDetails];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    NSNumber *isAborted = dict[@"isAborted"];
    XCTAssertTrue([isAborted boolValue]);
    
    self.session = [self.api startSessionWithProjectId:projectId
                                            projectURL:projectURL
                                                userId:nil
                                                  hash:nil
                                           description:nil];
    self.qrCodeURL = [NSString stringWithFormat:@"https://mcl.mpin.io/mobile-login/#%@",self.session.accessId];
    
    dict = [self.getCrossDeviceSessionCompatibilityCase getCrossDeviceSessionForQRCode:self.qrCodeURL];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    XCTAssertFalse([dict[@"crossDeviceSession"] isEqual:[NSNull null]]);
    
    universalLinkURL = [NSURL URLWithString:self.qrCodeURL];
    dict = [self.getCrossDeviceSessionCompatibilityCase getCrossDeviceSessionForUniversalLinkURL: universalLinkURL];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    XCTAssertFalse([dict[@"crossDeviceSession"] isEqual:[NSNull null]]);
    
    payload = @{
        @"userID" : self.userId,
        @"qrURL" : self.qrCodeURL,
        @"projectID": self.projectId
    };
    dict = [self.getCrossDeviceSessionCompatibilityCase getCrossDeviceSessionForPushNotificationsPayload: payload];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    XCTAssertFalse([dict[@"crossDeviceSession"] isEqual:[NSNull null]]);
    
    CrossDeviceSession *crossDeviceSession = (CrossDeviceSession *)dict[@"crossDeviceSession"];
    dict = [self.getCrossDeviceSessionCompatibilityCase abortCrossDeviceSession:crossDeviceSession];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    isAborted = dict[@"isAborted"];
    XCTAssertTrue([isAborted boolValue]);
    
    self.session = [self.api startSessionWithProjectId:projectId
                                            projectURL:projectURL
                                                userId:nil
                                                  hash:nil
                                           description:nil];
    self.qrCodeURL = [NSString stringWithFormat:@"https://mcl.mpin.io/mobile-login/#%@",self.session.accessId];
    
    dict = [self.getCrossDeviceSessionCompatibilityCase getCrossDeviceSessionForQRCode:self.qrCodeURL];
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    XCTAssertFalse([dict[@"crossDeviceSession"] isEqual:[NSNull null]]);
    self.crossDeviceSession = (CrossDeviceSession *) dict[@"crossDeviceSession"];
    
    NSURL *verificationURL = [self.api getVerificaitonURLWithServiceAccountToken:serviceAccountToken
                                                                       projectId:projectId
                                                                      projectURL:projectURL
                                                                          userId:self.userId
                                                                        accessId:self.session.accessId
                                                                      expiration:nil];
    dict = [self.getActivationTokenCompatiblityCase getActivationTokenFrom:verificationURL];
    self.activationToken = dict[@"activationToken"];
    
    dict = [self.registration registerUserWithId:self.userId
                                 activationToken:self.activationToken];
    
    XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
    
    __block User *user = [[MIRACLTrust getInstance] getUserBy:self.userId];
    XCTAssertFalse([user isEqual:[NSNull null]]);
    
    XCTestExpectation *waitForUser= [[XCTestExpectation alloc] initWithDescription:@"Wait for Async User Retrieval"];
    [[MIRACLTrust getInstance] getUserWithUserId:self.userId completionHandler:^(User * returnedUser, NSError* error) {
        user = returnedUser;
        [waitForUser fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[waitForUser]
                                                    timeout:10.0];
    XCTAssertFalse([user isEqual:[NSNull null]]);
    
    if (user != nil && result == XCTWaiterResultCompleted){
        dict = [self.authentication authenticateUser:user
                                              qrCode:self.qrCodeURL];
        
        NSNumber *isAuth = dict[@"isAuthenticated"];
        XCTAssertTrue([isAuth boolValue]);
        XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
        
        BOOL isAuthenticated = [isAuth boolValue];
        if (isAuthenticated) {
            
            NSString *message = [[NSUUID UUID] UUIDString];
            NSData *messageHash = [self messageHash:message];
            
            NSDate *date = [NSDate date];
            dict = [self.signing signWithMessage:messageHash
                                       timestamp:date
                                     signingUser:user];
            
            XCTAssertNotNil(dict[@"signature"]);
            XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
        } else {
            XCTFail("Error in authentication.");
        }
        
        dict = [self.jwtAuthentication authenticate:user];
        
        XCTAssertNotNil(dict[@"jwt"]);
        XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
        
        NSURL *url = [NSURL URLWithString:self.qrCodeURL];
        dict = [self.universalLinkAuthentication authenticateUser:user
                                                 universalLinkURL:url];
        
        isAuth = dict[@"isAuthenticated"];
        XCTAssertTrue([isAuth boolValue]);
        XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
        
        NSDictionary *payload = @{
            @"userID" : self.userId,
            @"qrURL" : self.qrCodeURL,
            @"projectID": self.projectId
        };
        dict = [self.pushNotificationAuthentication authenticateWithPayload:payload];
        isAuth = dict[@"isAuthenticated"];
        XCTAssertTrue([isAuth boolValue]);
        XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
        
        dict = [self.getCrossDeviceSessionCompatibilityCase
                authenticateWithUser:user
                crossDeviceSession: self.crossDeviceSession
                andPin: self.randomNumber];
        isAuth = dict[@"isAuthenticated"];
        XCTAssertTrue([isAuth boolValue]);
        XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
        
        dict = [self.quickCode generateQuickCodeFor:user];
        
        XCTAssertNotNil(dict[@"quickCode"]);
        XCTAssertTrue([dict[@"error"] isEqual:[NSNull null]]);
        
        // Try to Revoke User
        NSString *differentPinCode = [self randomNumberAsString];
        self.jwtAuthentication.pinCode = differentPinCode;
                
        dict = [self.jwtAuthentication authenticate:user];
        XCTAssertEqual(dict[@"jwt"], [NSNull null]);
        XCTAssertNotNil(dict[@"error"]);
        
        dict = [self.jwtAuthentication authenticate:user];
        XCTAssertEqual(dict[@"jwt"], [NSNull null]);
        XCTAssertNotNil(dict[@"error"]);

        dict = [self.jwtAuthentication authenticate:user];
        XCTAssertEqual(dict[@"jwt"], [NSNull null]);
        NSError *revokedError = (NSError *)dict[@"error"];
        XCTAssertEqualObjects(revokedError.description, @"MIRACLTrust.AuthenticationError.revoked");
  
        NSError *deletionError;
        [[MIRACLTrust getInstance] deleteWithUser:user error:&deletionError];
        
        if (deletionError != nil) {
            XCTFail(@"Deletion of user has failed");
            return;
        }
        
        NSString *anotherUserId = [[NSUUID UUID] UUIDString];
        verificationURL = [self.api getVerificaitonURLWithServiceAccountToken:serviceAccountToken
                                                                           projectId:projectId
                                                                          projectURL:projectURL
                                                                              userId:anotherUserId
                                                                            accessId:self.session.accessId
                                                                          expiration:nil];
        dict = [self.getActivationTokenCompatiblityCase getActivationTokenFrom:verificationURL];
        self.activationToken = dict[@"activationToken"];
        
        dict = [self.registration registerUserWithId:anotherUserId
                                     activationToken:self.activationToken];
        
        XCTestExpectation *expectationForAllUsers = [[XCTestExpectation alloc] initWithDescription:@"Wait for getting all users"];
        [[MIRACLTrust getInstance] getUsersWithCompletionHandler:^(NSArray<User *> * users, NSError * error) {
            XCTAssertEqual(users.count, 1);
            XCTAssertNil(error);
        }];
        [expectationForAllUsers fulfill];
        
        __block User *anotherUser = [[MIRACLTrust getInstance] getUserBy:anotherUserId];
        XCTestExpectation *expectationForDeletion = [[XCTestExpectation alloc] initWithDescription:@"Wait for another user deletion"];
        [[MIRACLTrust getInstance] deleteWithUser:anotherUser completionHandler:^(BOOL isDeleted, NSError * error) {
            XCTAssertTrue(isDeleted);
            XCTAssertNil(error);
            [expectationForDeletion fulfill];
        }];
        
        XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectationForDeletion]
                                                        timeout:10.0];
        if(result != XCTWaiterResultCompleted) {
            XCTFail(@"Cannot delete user asynchrouniusly");
        }
    }
}

- (void)tearDown
{
    [super tearDown];
    NSString *path = [DBFileHelper getDBFilePath];
    [NSFileManager.defaultManager removeItemAtPath:path
                                             error:nil];
    XCTAssertFalse([NSFileManager.defaultManager fileExistsAtPath:path]);
}

- (NSString *)randomNumberAsString
{
    int rndValue = 1000 + arc4random() % (9999 - 1000);
    return [NSString stringWithFormat:@"%d",rndValue];
}

-(NSData *)messageHash:(NSString *)message
{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *output = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_LONG length = @(data.length).unsignedIntValue;
    CC_SHA256(data.bytes, length, output.mutableBytes);
    
    return output;
}

@end
