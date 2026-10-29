# MIRACL Trust iOS SDK Sample

A sample application demonstrating user registration via
[Email Link verification](https://miracl.com/docs/guides/built-in-user-verification/email-link/)
and [user authentication](https://miracl.com/docs/guides/authentication/mobile-sdk/#authenticate-on-your-mobile-application)
within the app.

## Set up and run

### 1. Clone the repository and configure signing

Start by cloning the repository:

```sh
git clone https://github.com/miracl/trust-sdk-ios.git
cd trust-sdk-ios
```

Open the project in Xcode:

```sh
open Sample/Sample.xcodeproj
```

In the project navigator, select the **Sample** project, open the
**Sample** target's **Signing & Capabilities** tab, and configure
**Signing**:

- **Team:** Select your development team (must be an active
  [Apple Developer Program](https://developer.apple.com/programs/) account;
  free Personal Teams do not support the Associated Domains capability).
- **Bundle Identifier:** Enter a unique bundle identifier for the sample
  app (e.g., `com.<your-company>.trust.sample`).

### 2. Configure a project in the MIRACL Trust Portal

Go to the [MIRACL Trust Portal](https://trust.miracl.cloud) and create a project.

In the sidebar under **Configuration**, select **Mobile Applications**.
In the **iOS App Association** section, click **Add iOS app**
and enter your application details:

- **[Team ID](https://developer.apple.com/help/glossary/team-id/):** Your
  10-character Apple Developer Team ID.
- **Bundle Identifier:** The unique bundle identifier configured in
  Xcode (e.g., `com.<your-company>.trust.sample`).

Under **Configuration > General**, copy your **Project ID** and **Project Domain**.

### 3. Configure and run the app

In the project navigator, select `Config.xcconfig` and enter your project credentials:

```xcconfig
MIRACL_PROJECT_ID = <YOUR_PROJECT_ID>
// Raw host without protocol scheme (e.g., example.miracl.io)
MIRACL_PROJECT_DOMAIN = <YOUR_PROJECT_DOMAIN>
```

> **How Universal Links are configured:**  
> The sample pre-configures the **Associated Domains** capability with
> `applinks:$(MIRACL_PROJECT_DOMAIN)` in its `.entitlements` file. When
> integrating into your own app, you will need to add this capability
> manually in Xcode.

Build and run the sample on your target device or simulator.
