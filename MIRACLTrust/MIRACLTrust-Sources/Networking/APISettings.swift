import Foundation

/// URLs used to make a call to given MIRACL endpoints. This class is initialised when the [API] class instance is created from the response taken from the client settings.
struct APISettings: Sendable {
    let registrationURL: URL
    let authenticateURL: URL
    let pass1URL: URL
    let pass2URL: URL
    let verificationURL: URL
    let verificationConfirmationURL: URL
    let codeStatusURL: URL
    let dvsSessionURL: URL
    let dvsSessionDetailsURL: URL
    let verificationQuickCodeURL: URL

    init(platformURL: URL) {
        registrationURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/registration")!
        authenticateURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/rps/v2/authenticate")!
        pass1URL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/rps/v2/pass1")!
        pass2URL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/rps/v2/pass2")!
        verificationURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/verification/email")!
        verificationConfirmationURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/verification/confirmation")!
        codeStatusURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/rps/v2/codeStatus")!
        dvsSessionURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/dvs/session")!
        dvsSessionDetailsURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/dvs/session/details")!
        verificationQuickCodeURL = APISettings.createAPISettingsURL(platformURL: platformURL, path: "/verification/quickcode")!
    }

    static func createAPISettingsURL(platformURL: URL, path: String) -> URL? {
        var urlComponents = URLComponents(url: platformURL, resolvingAgainstBaseURL: false)
        urlComponents?.path = path
        return urlComponents?.url
    }
}
