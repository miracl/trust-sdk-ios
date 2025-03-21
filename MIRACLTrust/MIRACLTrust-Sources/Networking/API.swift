import Foundation

enum APICallResult: Int {
    case success
    case failed
}

/// Execute networking requests against MIRACL platform
/// - Tag: API
struct API: Sendable, APIBlueprint {
    let clientSettings: APISettings
    let baseURL: URL

    var executor: APIRequestExecutor
    let miraclLogger: MIRACLLogger

    init(
        baseURL: URL,
        urlSessionConfiguration: URLSessionConfiguration,
        miraclLogger: MIRACLLogger
    ) {
        self.baseURL = baseURL
        executor = APIRequestExecutor(
            urlSessionConfiguration: urlSessionConfiguration,
            miraclLogger: miraclLogger
        )
        self.miraclLogger = miraclLogger
        clientSettings = APISettings(platformURL: baseURL)
    }

    /// Registering user
    /// - Parameters:
    ///   - userId: id
    ///   - deviceName: device name
    ///   - activationToken: code
    ///   - completionHandler: handler
    /// - Tag: API-_FUNC_registeruserfordevicenameactivationtokencompletionhandler
    func registerUser(
        for userId: String,
        deviceName: String,
        activationToken: String,
        pushToken: String?,
        completionHandler: @escaping APIRequestCompletionHandler<RegistrationResponse>
    ) {
        let requestBody = RegistrationRequestBody()
        requestBody.activateCode = activationToken
        requestBody.deviceName = deviceName
        requestBody.userId = userId
        requestBody.pushToken = pushToken

        do {
            let request = try APIRequest(
                url: clientSettings.registerURL,
                path: nil,
                method: .put,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Creates signature.
    /// - Parameters:
    ///   - mpinId: mpinid
    ///   - regOTT: regott
    ///   - completionHandler: completion handler
    /// - Tag: API-_FUNC_signatureforregottcompletionhandler
    func signature(
        for mpinId: String,
        regOTT: String,
        publicKey: String,
        completionHandler: @escaping APIRequestCompletionHandler<SignatureResponse>
    ) {
        do {
            let request = try APIRequest(
                url: clientSettings.signatureURL,
                path: "/\(mpinId)",
                queryParameters: ["regOTT": regOTT, "publicKey": publicKey],
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )

            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Getting second client secret share
    /// - Parameters:
    ///   - cs2URL: url
    ///   - completionHandler: completion handler
    /// - Tag: API-_FUNC_getclientsecret2forcompletionhandler
    func getClientSecret2(
        for cs2URL: URL,
        completionHandler: @escaping APIRequestCompletionHandler<ClientSecretResponse>
    ) {
        do {
            let request = try APIRequest(
                url: cs2URL,
                path: nil,
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )

            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Server pass1
    /// - Parameters:
    ///   - dtas: dtas
    ///   - mpinId: mpinid
    ///   - publicKey: publickey
    ///   - uValue: u
    ///   - scope: scoper
    ///   - completionHandler: completion handler
    /// - Tag: API-_FUNC_pass1formpinidpublickeyuvaluescopecompletionhandler
    func pass1(
        for dtas: String,
        mpinId: String,
        publicKey: String?,
        uValue: String,
        scope: [String],
        completionHandler: @escaping APIRequestCompletionHandler<Pass1Response>
    ) {
        do {
            let pass1RequestBody = Pass1RequestBody()
            pass1RequestBody.dtas = dtas
            pass1RequestBody.mpinId = mpinId
            pass1RequestBody.uValue = uValue
            pass1RequestBody.scope = scope
            pass1RequestBody.publicKey = publicKey

            let request = try APIRequest(
                url: clientSettings.pass1URL,
                path: nil,
                method: .post,
                requestBody: pass1RequestBody,
                miraclLogger: miraclLogger
            )
            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Server pass 2
    /// - Parameters:
    ///   - mpinId: mpinid
    ///   - accessId: accessid
    ///   - vValue: vvalue
    ///   - completionHandler: completion handler
    /// - Tag: API-_FUNC_pass2foraccessidvvaluecompletionhandler
    func pass2(
        for mpinId: String,
        accessId: String?,
        vValue: String,
        completionHandler: @escaping APIRequestCompletionHandler<Pass2Response>
    ) {
        do {
            let pass2RequestBody = Pass2RequestBody()
            pass2RequestBody.mpinId = mpinId
            pass2RequestBody.vValue = vValue
            pass2RequestBody.accessId = accessId

            let request = try APIRequest(
                url: clientSettings.pass2URL,
                path: nil,
                method: .post,
                requestBody: pass2RequestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Authenticate
    /// - Parameters:
    ///   - authOTT: authentication token
    ///   - completionHandler: completion handler
    /// - Tag: API-_FUNC_authenticateauthottcompletionhandler
    func authenticate(
        authOTT: String,
        completionHandler: @escaping APIRequestCompletionHandler<AuthenticateResponse>
    ) {
        do {
            let requestBody = AuthenticateRequestBody()
            requestBody.authOTT = authOTT

            let request = try APIRequest(
                url: clientSettings.authenticateURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .millisecondsSince1970

            executor.execute(apiRequest: request,
                             jsonDecoder: jsonDecoder,
                             completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Get client secret 1 for signing
    /// - Parameters:
    ///   - publicKey: public key
    ///   - signingRegistrationToken: token
    ///   - deviceName: device identifier into the portal application.
    ///   - completionHandler: completion handler
    /// - Tag: API-_FUNC_signingclientsecret1publickeysigningregistrationtokendevicenamecompletionhandler
    func signingClientSecret1(
        publicKey: String,
        signingRegistrationToken: String,
        deviceName: String,
        completionHandler: @escaping APIRequestCompletionHandler<SigningClientSecret1Response>
    ) {
        let requestBody = SigningClientSecret1RequestBody()
        requestBody.dvsRegisterToken = signingRegistrationToken
        requestBody.publicKey = publicKey
        requestBody.deviceName = deviceName

        do {
            let request = try APIRequest(
                url: clientSettings.dvsRegURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Sending request for verifying user identity.
    /// - Parameters:
    ///   - projectId: id of the project
    ///   - userId: id of the user.
    ///   - deviceName: a device identifier used to recognise device in the portal.
    ///   - accessId: a session identifier used to get information from web session.
    ///   - mpinId: user's mpinId if it is already registered.
    ///   - completionHandler: completion handler.
    /// - Tag: API-_FUNC_verifyuserfordevicenameaccessidcompletionhandler
    func verifyUser(
        projectId: String,
        userId: String,
        deviceName: String,
        accessId: String?,
        mpinId: String?,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationRequestResponse>
    ) {
        let requestBody = VerificationRequestBody(
            projectId: projectId,
            userId: userId,
            deviceName: deviceName,
            accessId: accessId,
            mpinId: mpinId
        )

        do {
            let request = try APIRequest(
                url: clientSettings.verificationURL,
                path: nil,
                method: .post,
                queryParameters: nil,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )
            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    /// Sending request for confirming user identity verification.
    /// - Parameters:
    ///   - userId: id of the user.
    ///   - code: activation code.
    ///   - completionHandler: completion handler.
    /// - Tag: API-_FUNC_confirmverificationrequestuseridcodecompletionhandler
    func confirmVerificationRequest(
        userId: String,
        code: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationConfirmationResponse>
    ) {
        let requestBody = VerificationConfirmationRequestBody()
        requestBody.code = code
        requestBody.userId = userId

        do {
            let request = try APIRequest(
                url: clientSettings.verificationConfirmationURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970

            executor.execute(apiRequest: request,
                             jsonDecoder: jsonDecoder,
                             completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func getSessionDetails(
        accessId: String,
        completionHandler: @escaping APIRequestCompletionHandler<AuthenticationSessionsDetailsResponse>
    ) {
        let requestBody = CodeStatusRequestBody(
            wid: accessId,
            status: "wid"
        )
        do {
            let request = try APIRequest(
                url: clientSettings.codeStatusURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func abortSession(
        accessId: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    ) {
        let requestBody = CodeStatusRequestBody(
            wid: accessId,
            status: "abort"
        )
        do {
            let request = try APIRequest(
                url: clientSettings.codeStatusURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func updateCodeStatus(
        accessId: String,
        userId: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    ) {
        let requestBody = CodeStatusRequestBody(
            wid: accessId,
            status: "user",
            userId: userId
        )

        do {
            let request = try APIRequest(
                url: clientSettings.codeStatusURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func getSigningSessionDetails(
        accessId: String,
        completionHandler: @escaping APIRequestCompletionHandler<SigningSessionDetailsResponse>
    ) {
        do {
            let requestBody = SigningSessionDetailsRequestBody(
                id: accessId
            )

            let request = try APIRequest(
                url: clientSettings.dvsSessionDetailsURL,
                path: nil,
                method: .post,
                queryParameters: nil,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func updateSigningSession(
        identifier: String,
        signature: Signature,
        timestamp: Date,
        completionHandler: @escaping APIRequestCompletionHandler<SigningSessionCompleterResponse>
    ) {
        do {
            let requestBody = SigningSessionUpdaterRequestBody(
                id: identifier,
                signature: signature,
                timestamp: Int64(timestamp.timeIntervalSince1970)
            )

            let request = try APIRequest(
                url: clientSettings.dvsSessionURL,
                path: nil,
                method: .put,
                queryParameters: nil,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func abortSigningSession(
        sessionId: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    ) {
        do {
            let abortSigningSessionRequestBody = SigningSessionAborterRequestBody(id: sessionId)

            let request = try APIRequest(
                url: clientSettings.dvsSessionURL,
                path: nil,
                method: .delete,
                queryParameters: nil,
                requestBody: abortSigningSessionRequestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func quickCodeVerificationRequest(
        projectId: String,
        jwt: String,
        deviceName: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationQuickCodeResponse>
    ) {
        do {
            let requestBody = VerificationQuickCodeRequestBody(
                projectId: projectId,
                jwt: jwt,
                deviceName: deviceName
            )

            let request = try APIRequest(
                url: clientSettings.verificationQuickCodeURL,
                path: nil,
                method: .post,
                queryParameters: nil,
                requestBody: requestBody,
                miraclLogger: miraclLogger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }
}
