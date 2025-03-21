import Foundation

/**
 HTTP response object received in a completion block after a call to [confirmVerificationRequest](x-source-tag://API-_FUNC_confirmverificationrequestuseridcodecompletionhandler) method of the [API](x-source-tag://API) class.
 */
struct VerificationConfirmationResponse: Codable {
    var projectId: String = ""
    var accessId: String?
    var actToken: String = ""
}
