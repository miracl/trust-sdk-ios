# MIRACL Trust iOS SDK

The MIRACL Trust iOS SDK provides the following functionalities:

- [User ID Verification](#user-id-verification)
- [Registration](#registration)
- [Authentication](#authentication)
- [Signing](#signing)
- [QuickCode](#quickcode)

## System Requirements

- Xcode 10 or newer
- iOS 11 or newer
- Swift 4.2 or newer

## Installation

### Swift Package Manager

If you use Xcode go to `Project Settings` -> `Package Dependencies`
-> Click the add button (+) and add the package repo:

```bash
https://github.com/miracl/trust-sdk-ios
```

To integrate using Apple's Swift package manager, without
Xcode integration, add the following as a dependency to your Package.swift:

```bash
.package(url: "https://github.com/miracl/trust-sdk-ios", .upToNextMajor(from: "1.0.0"))
```

In both cases after the package is downloaded, go to the
Target's `General` tab, Expand the
`Frameworks, Libraries, and Embedded Content` section,
click the Add button (+) and select `MIRACLTrust` framework.

### Manual

Drag and drop the XCFramework to your application.

## Usage

### SDK Configuration

To configure the SDK:

1. Create an application in the MIRACL Trust platform. For information about how
   to do it, see the
   [Getting Started](https://miracl.com/resources/docs/guides/get-started/)
   guide.
2. Call the
   [configure](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#configurewith)
   method with a configuration created by the [Configuration.Builder](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/Configuration.Builder/)
   class:

Swift:

```swift
let projectId = <#Enter your Project ID here#>
let deviceName = <#Enter your device name here or use UIDevice.current.modelName provided by MIRACL SDK #>

do {
    let configuration = try Configuration
        .Builder(
            projectId: projectId,
            deviceName: deviceName
        ).build()
    try MIRACLTrust.configure(with: configuration)
} catch {
    <#Handle error as appropriate#>
}
```

Objective-C:

```objc
NSString *projectId = <#Enter your Project ID#>;
NSString *deviceName = <#Enter your device name here or use UIDevice.current.modelName provided by MIRACL SDK #>;
NSError *configurationError;

ConfigurationBuilder *configurationBuilder =
    [[ConfigurationBuilder alloc] initWithProjectId:projectId deviceName: deviceName];
Configuration *configuration =
    [configurationBuilder buildAndReturnError:&configurationError];

if (configurationError == nil) {
    [[MIRACLTrust configureWith:configuration
                          error:&configurationError];

    if (configurationError != nil) {
        <#Handle error as appropriate#>
    }
}
```

Call the
[configure](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#configurewith)
method as early as possible in the application lifecycle and avoid using the
[getInstance](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#getinstance)
method before that; otherwise assertion will be triggered.

`deviceName` is an identifier that can help find the device on the MIRACL Trust Portal.
For `iOS`, the MIRACL Trust SDK provides an
[extension](https://miracl.com/resources/docs/apis-and-libraries/ios/extensions/UIDevice/)
of `UIDevice` that returns the actual model name of the device
(e.g iPhone 16 Pro Max). This extension value can be passed to the
[Configuration.Builder](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/Configuration.Builder)
constructor. By default, the value of `deviceName` is the name of
the operation system (e.g `iOS`).

### Obtain instance of the SDK

To obtain an instance of the SDK, call the [getInsatnce](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#getinstance)
method:

Swift:

```swift
let miraclTrust = MIRACLTrust.getInstance()
```

Objective-C:

```objc
MIRACLTrust *miraclTrust = [MIRACLTrust getInstance];
```

### User ID Verification

To register a new User ID, you need to verify it. MIRACL
offers two options for that:

- [Custom User Verification](https://miracl.com/resources/docs/guides/custom-user-verification/)
- [Built-in User Verification](https://miracl.com/resources/docs/guides/built-in-user-verification/)

  With this type of verification, the end user's email address
  serves as the User ID. Currently, MIRACL Trust provides two kinds of built-in
  email verification methods:

  - [Email Link](https://miracl.com/resources/docs/guides/built-in-user-verification/email-link/)
    (default)
  - [Email Code](https://miracl.com/resources/docs/guides/built-in-user-verification/email-code/)

  Start the verification by calling the
  [sendVerificationEmail](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#sendverificationemailuseridauthenticationsessiondetailscompletionhandler)
  method:

  Swift:

  ```swift
      MIRACLTrust.getInstance().sendVerificationEmail(
          userId: <#Unique user identifier (any string, i.e. email)#>
      ) { (verificationResponse, error) in
         // Check here if verification email is sent and handle any verification errors.
      }
  ```

  Objective-C:

  ```objc
      [[MIRACLTrust getInstance]
          sendVerificationEmailWithUserId: <#Unique user identifier#>
             authenticationSessionDetails: nil
                        completionHandler: ^(VerificationResponse *verificationResponse, NSError * _Nullable error) {
                            // Check here if verification email
                            // is sent and handle any verification errors.
                        }];
  ```

  Then, a verification email is sent, and a
  [VerificationResponse](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/VerificationResponse/)
  with backoff and email verification method is returned.

  If the verification method you have chosen for your project is:

  - **Email Code:**

    You must check the email verification method in the response.

    - If the end user is registering for the first time or resetting their PIN,
      an email with a verification code will be sent, and the email
      verification method in the response will be
      [EmailVerificationMethod.code](https://miracl.com/resources/docs/apis-and-libraries/ios/enums/EmailVerificationMethod/#code).
      Then, ask the user to enter the code in the application.

    - If the end user has already registered another device with the same
      User ID, a Verification URL will be sent, and the verification method in
      the response will be
      [EmailVerificationMethod.link](https://miracl.com/resources/docs/apis-and-libraries/ios/enums/EmailVerificationMethod/#link).
      In this case, proceed as described for the **Email Link** verification
      method below.

  - **Email Link:** Your application must open when the end user follows
    the Verification URL in the email. To ensure proper deep linking behaviour
    on mobile applications, use
    [Apple's Universal Links](https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content).
    To associate your application with the email Verification URL, use the
    **iOS app association** field in **Mobile Applications** under
    **Configuration** in the [MIRACL Trust Portal](https://trust.miracl.cloud).

### Registration

1. To register the mobile device, get an activation token. This happens in two
   different ways depending on type of verification.

   - [Custom User Verification](https://miracl.com/resources/docs/guides/custom-user-verification/)
     or [Email Link](https://miracl.com/resources/docs/guides/built-in-user-verification/email-link/):

      After the application recieves the Verification URL, it must confirm the
      verification by passing it to the
      [getActivationToken](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#getactivationtokenverificationurlcompletionhandler)
      method:

      Swift:

      ```swift
      func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
          guard let verificationURL = userActivity.webpageURL else {
              return
          }

          MIRACLTrust
              .getInstance()
              .getActivationToken(verificationURL: verificationURL) { activationTokenResponse, error in
                      // Pass the activation token to the `register` method.
              }
      }
      ```

      Objective-C:

      ```objc
      -(void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity
      {
          if(userActivity.webpageURL == nil) {
              return;
          }

          NSURL *verificationURL = userActivity.webpageURL;

          [[MIRACLTrust getInstance]
              getActivationTokenWithVerificationURL:verificationURL
              completionHandler: ^(ActivationTokenResponse * _Nullable activationTokenResponse,
                                  NSError * _Nullable error) {
                                  // Pass the activation token to the `register` method.
              }];
      }
      ```

      Call this method after the Universal Link is handled in the application. For
      `UIKit` applications, use the
      [scene](https://developer.apple.com/documentation/uikit/uiscenedelegate/3238056-scene)
      or
      [application](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623072-application)
      delegate methods. For `SwiftUI`, use the
      [onOpenURL](<https://developer.apple.com/documentation/SwiftUI/View/onOpenURL(perform:)>)
      modifier.

   - [Email Code](https://miracl.com/resources/docs/guides/built-in-user-verification/email-code/):

      When the end user enters the verification code, the application must
      confirm the verification by passing it to the
      [getActivationToken](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#getactivationtokenuseridcodecompletionhandler)
      method:

      Swift:

      ```swift
      MIRACLTrust
         .getInstance()
         .getActivationToken(userId: userId, code: code) { activationTokenResponse, error in
               // Pass the activation token to the `register` method.
         }
      ```

      Objective-C:

      ```objc
      [[MIRACLTrust getInstance]
      getActivationTokenWithUserId:userId
      code:code
      completionHandler:^(ActivationTokenResponse * _Nullable response, NSError * _Nullable error) {

         // Pass the activation token to the `register` method.
      }];
      ```

2. Pass the User ID (email or any string you use for identification), activation
   token (received from verification), [PinRequestHandler](https://miracl.com/resources/docs/apis-and-libraries/ios/typealiases/PinRequestHandler/)
   and [RegistrationCompletionHandler](https://miracl.com/resources/docs/apis-and-libraries/ios/typealiases/RegistrationCompletionHandler/)
   implementations to the [register](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/#registerforactivationtokenpushnotificationstokendidrequestpinhandlercompletionhandler)
   method. When the registration is successful, a [RegistrationCompletionHandler](https://miracl.com/resources/docs/apis-and-libraries/ios/typealiases/RegistrationCompletionHandler/)
   callback is returned, passing the registered user. Otherwise [RegistrationError](https://miracl.com/resources/docs/apis-and-libraries/ios/enums/RegistrationError/)
   is passed in the callback.

   Swift:

   ```swift
   MIRACLTrust.getInstance().register(
       for: <#Unique user identifier (any string, i.e. email)#>,
       activationToken: <#Activation token#>,
       didRequestPinHandler: { pinProcessor in
           // Here the user creates a PIN code for their new User ID.

           pinProcessor(<#Provide your PIN code here#>)
       },
       completionHandler: { user, error in
       // Get the user object or handle the error appropriately.
       }
   )
   ```

   Objective-C:

   ```objc
   [[MIRACLTrust getInstance] registerFor:<#Unique user identifier (any string, i.e. email)#>
                       activationToken:<#Activation token#>
                   pushNotificationsToken:<#Push notifications token#>
                   didRequestPinHandler:^(void (^ _Nonnull pinProcessor)(NSString *)) {
                       // Here the user creates a PIN code for their new User ID.

                       pinProcessor(<#Provide your PIN code here#>)
                   } completionHandler:^(User * _Nullable user, NSError * _Nullable error) {
                       // Get the user object or handle the error appropriately.
                   }];
   ```

   If you call the
   [register](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/#registerforactivationtokenpushnotificationstokendidrequestpinhandlercompletionhandler)
   method with the same User ID more than once, the User ID will be overridden.
   Therefore, you can use it when you want to reset your authentication PIN
   code.

### Authentication

The MIRACL Trust SDK offers two options:

- [Authenticate users on the mobile application](#authenticate-users-on-the-mobile-application)
- [Authenticate users on another application](#authenticate-users-on-another-application)

#### Authenticate users on the mobile application

The
[authenticate](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#authenticateuserdidrequestpinhandlercompletionhandler)
method generates a [JWT](https://jwt.io) authentication token for а registered
user.

Swift:

```swift
    MIRACLTrust.getInstance().authenticate(
        user: <#Already registered user object#>
    ) { pinHandler in
        // Here the user provides their current User ID's PIN code.

        pinHandler(<#Provide your PIN here#>)
    } completionHandler: { jwt, error in
        // Get the JWT or handle the error appropriately.
    }
```

Objective-C:

```objc
[[MIRACLTrust getInstance] authenticate:<#Already registered user object#>
                   didRequestPinHandler:^(void (^ _Nonnull pinHandler)(NSString * _Nullable)) {
                         pinHandler(<#Provide your PIN here#>);
                    } completionHandler:^(NSString * _Nullable jwt, NSError * _Nullable error) {
                          // Get the JWT or handle the error appropriately.
                    }];
```

After the JWT authentication token is generated, it needs to be sent to the
application server for verification. Then, the application server verifies the
token signature using the MIRACL Trust
[JWKS](https://api.mpin.io/.well-known/jwks) endpoint and the `audience` claim,
which in this case is the application Project ID.

#### Authenticate users on another application

To authenticate a user on another application, there are three options:

- Authenticate with
  [Universal Links](https://developer.apple.com/ios/universal-links/)

  Use the [authenticateWithUniversalLinkURL](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#authenticatewithuniversallinkurluseruniversallinkurldidrequestpinhandlercompletionhandler)
  method:

  Swift:

  ```swift
  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
      guard let universalLinkURL = userActivity.webpageURL else {
          return
      }

      MIRACLTrust.getInstance().authenticateWithUniversalLinkURL(
          user: <#Already registered user object#>,
          universalLinkURL: universalLinkURL
      ) { pinHandler in
          // Here the user provides their current User ID's PIN code.

          pinHandler(<#Provide your PIN here#>)
      } completionHandler: { isAuthenticated, error in
          // Handle your authentication result here.
      }
  }
  ```

  Objective-C:

  ```objc
  -(void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
      if(userActivity.webpageURL == nil) {
          return;
      }

      NSURL *universalLinkURL = userActivity.webpageURL;

      [[MIRACLTrust getInstance] authenticateWithUser:<#Already registered user object#>
          universalLinkURL:universalLinkURL
      didRequestPinHandler:^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
          pinHandler(<#Provide your PIN here#>);
      } completionHandler:^(BOOL isAuthenticated, NSError * _Nullable error) {
          // Handle your authentication result here.
      }];
  }
  ```

If your application doesn't use `UIScene`, add the
`authenticateWithUniversalLinkURL` implementation to the
`application:continueUserActivity:restorationHandler:` implementation in the
Application Delegate.

If using `SwiftUI`, use the `onOpenURL` modifier.

- Authenticate with QR code

  Use the [authenticateWithQRCode](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#authenticatewithqrcodeuserqrcodedidrequestpinhandlercompletionhandler)
  method:

  Swift:

  ```swift
      MIRACLTrust.getInstance().authenticateWithQRCode(
          user: <#Already registered user object#>,
          qrCode: <#QR code taken from a MIRACL page#>,
          didRequestPinHandler: { pinProcessor in
              // Here the user provides their current User ID's PIN code.

              pinProcessor(<#Provide your PIN code here#>)
          }, completionHandler: { isAuthenticatedResult, error in
              // Handle your authentication result here.
          }
      )
  ```

  Objective-C:

  ```objc
  [[MIRACLTrust getInstance]
      authenticateWithUser:<#Already registered user object#>
                    qrCode:<#QR code taken from a MIRACL page#>
      didRequestPinHandler:^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
          // Here the user provides their current User ID's PIN code.

          pinProcessor(<#Provide your PIN here#>);
      } completionHandler:^(BOOL isAuthenticated, NSError * _Nullable error) {
          // Handle your authentication result here.
      }];
  ```

- Authenticate with
  [push notifications](https://developer.apple.com/notifications/) payload:

  Use the [authenticateWithPushNotificationPayload](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#authenticatewithpushnotificationpayloadpayloaddidrequestpinhandlercompletionhandler)
  method:

  Swift:

  ```swift
  func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      didReceive response: UNNotificationResponse,
      withCompletionHandler completionHandler: @escaping () -> Void
  ) {
      let pushPayload = response.notification.request.content.userInfo

      MIRACLTrust
          .getInstance()
          .authenticateWithPushNotificationPayload(
              payload: pushPayload,
              didRequestPinHandler: { pinProcessor in
                  // Here the user provides their current User ID's PIN code.

                  pinProcessor(<#Provide your PIN code here#>)
              },
              completionHandler: { isAuthenticatedResult, error in
                  // Handle your authentication result here.
              }
          )
  }
  ```

  Objective-C:

  ```objc
  - (void)userNotificationCenter:(UNUserNotificationCenter *)center
         willPresentNotification:(UNNotification *)notification
           withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
  {
      NSDictionary *pushPayload = notification.request.content.userInfo;

      [[MIRACLTrust getInstance]
          authenticateWithPushNotificationPayload:pushPayload
          didRequestPinHandler:^(void (^ _Nonnull pinHandler)(NSString * _Nullable)) {
              // Here the user provides their current User ID's PIN code.

              pinProcessor(<#Provide your PIN here#>);
          } completionHandler:^(BOOL isAuthenticated, NSError * _Nullable error) {
              // Handle your authentication result here.
          }];
  }
  ```

For more information about authenticating users on custom applications, see
[Cross-Device Authentication](https://miracl.com/resources/docs/guides/how-to/custom-mobile-authentication/).

### Signing

DVS stands for Designated Verifier Signature, which is a protocol for
cryptographic signing of documents. For more information, see
[Designated Verifier Signature](https://miracl.com/resources/docs/concepts/dvs/).
In the context of this SDK, we refer to it as 'Signing'.

To sign a document, use the
[sign](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#signmessagetimestampusersigningsessiondetailsdidrequestsigningpinhandlercompletionhandler)
method as follows:

Swift:

```swift
MIRACLTrust.getInstance().sign(
    message: <#Message hash#> ,
    user: <#Already registered user#>,
    didRequestSigningPinHandler: { pinProcessor in
        // Here the user provides their current signing PIN.

        pinProcessor(<#Provide your signing user PIN here#>)
    }, completionHandler: { signingResult, error in
        // The signingResult object contains signature and timestamp,
        // and can be sent for verification.
    }
)
```

Objective-C:

```objc
[[MIRACLTrust getInstance] signWithMessage: <#Message hash#>
                                      user: <#Already registered signing user#>
               didRequestSigningPinHandler: ^(void (^ _Nonnull pinProcessor)(NSString * _Nullable)) {
                    // Here the user provides their current signing PIN.

                    pinProcessor(<#Provide your signing user PIN here#>);
                } completionHandler: ^(SigningResult * _Nullable signingResult, NSError * _Nullable error) {
                    // The signingResult object contains signature and timestamp,
                    // and can be sent for verification.
                }];
```

The signature is generated from a document hash. To get this hash, you can use
the [CryptoKit](https://developer.apple.com/documentation/cryptokit) or
[CommonCrypto](https://developer.apple.com/library/archive/documentation/Security/Conceptual/cryptoservices/Introduction/Introduction.html)
frameworks.

The signature needs to be verified. This is done when the signature and the
timestamp are sent to the application server, which then makes a call to the
[POST /dvs/verify](https://miracl.com/resources/docs/guides/dvs/dvs-web-plugin/#api-reference)
endpoint. If the MIRACL Trust platform returns status code `200`, the
`certificate` entry in the response body indicates that signing is successful.

### QuickCode

[QuickCode](https://miracl.com/resources/docs/guides/built-in-user-verification/quickcode/)
is a way to register another device without going through the verification
process.

To generate a QuickCode, call the [generateQuickCode](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/index.html#generatequickcodeuserdidrequestpinhandlercompletionhandler)
method with an already registered [User](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/User/)
object:

Swift:

```swift
MIRACLTrust.getInstance().generateQuickCode(
    for: <#Already registered user#>,
    didRequestPinHandler: { pinHandler in
        // Here the user provides their current User ID's PIN code.
        pinHandler(<#Provide your user PIN here#>)
    },
    completionHandler: { quickCode, error in
        // Get the QuickCode object or handle the error appropriately.
    }
)
```

Objective-C:

```objc
 [[MIRACLTrust getInstance]
        generateQuickCode:<#Already registered  user#>
     didRequestPinHandler:^(void (^ _Nonnull pinHandler)(NSString * _Nullable)) {
        // Here the user provides their current authentication PIN.

        pinHandler(<#Provide your user PIN here#>);
     } completionHandler:^(QuickCode * _Nullable quickCode , NSError * _Nullable error) {
        // Get the QuickCode object or handle the error appropriately.
     }];
```

## FAQ

1. How to provide a PIN code?

   For security reasons, the PIN code is sent to the SDK at the last possible
   moment. A [PinRequestHandler](https://miracl.com/resources/docs/apis-and-libraries/ios/typealiases/PinRequestHandler/)
   is responsible for that and when the SDK calls it, the currently executed
   operation is blocked until a PIN code is provided. Therefore, this is a good
   place to display some user interface for entering the PIN code. For example:

   Swift:

   ```swift
   MIRACLTrust.getInstance().register(
       for: <#Unique user identifier(i.e. email)#>,
       activationToken: <#Activation token#>,
       didRequestPinHandler: { pinProcessor in
           let enterPinViewController = EnterPinViewController()
           enterPinViewController.pinProcessor = pinProcessor

           present(enterPinViewController, animated:true)
       },
       completionHandler: { user, error in
          // Get the user object or handle the error appropriately.
       }
   )
   ```

   In the view controller for entering the PIN code, you need to call the
   [pinProcessor](https://miracl.com/resources/docs/apis-and-libraries/ios/typealiases/ProcessPinHandler/)
   closure, which sends the PIN code to the SDK and restores the previously
   executed operation:

   Swift:

   ```swift
   func submitPINCode() {
       let pinCodeText = <#Get your PIN code here.>

       pinProcessor(pinCodeText)
   }
   ```

2. What is Activation Token?

   Activation Token is the value that links the verification flow with the
   registration flow. The value is returned by the verification flow and needs
   to be passed to the
   [register](https://miracl.com/resources/docs/apis-and-libraries/ios/classes/MIRACLTrust/#registerforactivationtokenpushnotificationstokendidrequestpinhandlercompletionhandler)
   method so the platform can verify it. Here are the options for that:

   - [Custom User Verification](https://miracl.com/resources/docs/guides/custom-user-verification/)
   - [Built-in User Verification](https://miracl.com/resources/docs/guides/built-in-user-verification/)

3. What is Project ID?

   Project ID is a common identifier of applications in the MIRACL Trust
   platform that share a single owner.

   You can find the Project ID value in the MIRACL Trust Portal:

   1. Go to [trust.miracl.cloud](https://trust.miracl.cloud).
   2. Log in or create a new User ID.
   3. Select your project.
   4. In the CONFIGURATION section, go to **General**.
   5. Copy the **Project ID** value.

## Documentation

- See an overview of the mobile integration at
  [miracl.com/resources/docs/guides/mobile/](https://miracl.com/resources/docs/guides/mobile/)
