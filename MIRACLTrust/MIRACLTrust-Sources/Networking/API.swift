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
    let logger: Logger

    init(
        baseURL: URL,
        urlSessionConfiguration: URLSessionConfiguration,
        logger: Logger
    ) {
        self.baseURL = baseURL
        executor = APIRequestExecutor(
            urlSessionConfiguration: urlSessionConfiguration,
            logger: logger
        )
        self.logger = logger
        clientSettings = APISettings(platformURL: baseURL)
    }

    func registerUser(
        userId: String,
        activationToken: String,
        deviceName: String,
        publicKey: String,
        pushToken: String?,
        completionHandler: @escaping APIRequestCompletionHandler<RegistrationResponse>
    ) {
        let registrationRequestBody = RegistrationRequestBody(
            userId: userId,
            deviceName: deviceName,
            activationToken: activationToken,
            publicKey: publicKey,
            pushToken: pushToken
        )

        do {
            let request = try APIRequest(
                url: clientSettings.registrationURL,
                path: nil,
                method: .post,
                requestBody: registrationRequestBody,
                logger: logger
            )

            executor.execute(apiRequest: request, completion: completionHandler)
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func getClientSecretShare(
        _ clientSecretShareURL: URL,
        completionHandler: @escaping APIRequestCompletionHandler<ClientSecretResponse>
    ) {
        do {
            let request = try APIRequest(
                url: clientSecretShareURL,
                path: nil,
                requestBody: EmptyRequestBody(),
                logger: logger
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
                logger: logger
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
                logger: logger
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
                logger: logger
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
                logger: logger
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
                logger: logger
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

    func getCrossDeviceSession(
        sessionId: String,
        completionHandler: @escaping APIRequestCompletionHandler<CrossDeviceSessionResponse>
    ) {
        let requestBody = CodeStatusRequestBody(
            wid: sessionId,
            status: "wid"
        )

        do {
            let request = try APIRequest(
                url: clientSettings.codeStatusURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                logger: logger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
        } catch {
            completionHandler(.failed, nil, error)
        }
    }

    func updateCrossDeviceSessionForSigning(
        sessionId: String,
        signature: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    ) {
        let requestBody = CodeStatusRequestBody(
            wid: sessionId,
            status: "signed",
            userId: nil,
            signature: signature
        )

        do {
            let request = try APIRequest(
                url: clientSettings.codeStatusURL,
                path: nil,
                method: .post,
                requestBody: requestBody,
                logger: logger
            )

            executor.execute(
                apiRequest: request,
                completion: completionHandler
            )
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
                logger: logger
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
                logger: logger
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
                logger: logger
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
                logger: logger
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
                logger: logger
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
                logger: logger
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
                logger: logger
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
