import Foundation

extension MIRACLTrust {
    func sendVerificationEmailCore(
        userId: String,
        crossDeviceSession: CrossDeviceSession,
        completionHandler: @escaping VerificationCompletionHandler
    ) {
        do {
            let verificator = try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                sessionIdentifier: crossDeviceSession.sessionId,
                miraclAPI: miraclAPI,
                deviceTagManager: deviceTagManager,
                logger: logger,
                completionHandler: completionHandler
            )
            verificator.verify()
        } catch {
            logError(error: error, category: .verification)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func sendVerificationEmailCore(
        userId: String,
        completionHandler: @escaping VerificationCompletionHandler
    ) {
        do {
            let verificator = try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                sessionIdentifier: nil,
                miraclAPI: miraclAPI,
                deviceTagManager: deviceTagManager,
                logger: logger,
                completionHandler: completionHandler
            )
            verificator.verify()
        } catch {
            logError(error: error, category: .verification)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func getActivationTokenCore(
        verificationURL: URL,
        completionHandler: @escaping ActivationTokenCompletionHandler
    ) {
        do {
            let handler = try VerificationConfirmationHandler(
                verificationURL: verificationURL,
                miraclAPI: miraclAPI,
                deviceTagManager: deviceTagManager,
                logger: logger,
                completionHandler: completionHandler
            )
            handler.handle()
        } catch {
            logError(error: error, category: .verificationConfirmation)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func getActivationTokenCore(
        userId: String,
        code: String,
        completionHandler: @escaping ActivationTokenCompletionHandler
    ) {
        do {
            let handler = try VerificationConfirmationHandler(
                userId: userId,
                activationCode: code,
                miraclAPI: miraclAPI,
                deviceTagManager: deviceTagManager,
                logger: logger,
                completionHandler: completionHandler
            )
            handler.handle()
        } catch {
            logError(error: error, category: .verificationConfirmation)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func generateQuickCodeCore(
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping QuickCodeCompletionHandler
    ) {
        let generator = QuickCodeGenerator(
            user: user,
            api: miraclAPI,
            deviceName: deviceName,
            storage: userStorage,
            crypto: crypto,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler
        ) { quickCode, error in
            completionHandler(quickCode, error)
        }
        generator.generate()
    }

    func registerCore(
        for userId: String,
        activationToken: String,
        pushNotificationsToken: String? = nil,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping RegistrationCompletionHandler
    ) {
        do {
            let registrator = try Registrator(
                userId: userId,
                activationToken: activationToken,
                deviceName: deviceName,
                pushNotificationsToken: pushNotificationsToken,
                api: miraclAPI,
                userStorage: userStorage,
                projectId: projectId,
                crypto: crypto,
                logger: logger,
                deviceTagManager: deviceTagManager,
                didRequestPinHandler: didRequestPinHandler,
                completionHandler: completionHandler
            )
            registrator.register()
        } catch {
            logError(error: error, category: .registration)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func authenticateCore(
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping JWTCompletionHandler
    ) {
        let jwtGenerator = JWTGenerator(
            user: user,
            miraclAPI: miraclAPI,
            deviceName: deviceName,
            userStorage: userStorage,
            crypto: crypto,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: completionHandler
        )
        jwtGenerator.generate()
    }

    func getCrossDeviceSessionFromQRCodeCore(
        qrCode: String,
        completionHandler: @escaping CrossDeviceSessionCompletionHandler
    ) {
        do {
            let fetcher = try CrossDeviceSessionFetcher(
                qrCode: qrCode,
                miraclAPI: miraclAPI,
                logger: logger,
                completionHandler: completionHandler
            )

            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func getCrossDeviceSessionFromUniversalLinkURLCore(
        universalLinkURL: URL,
        completionHandler: @escaping CrossDeviceSessionCompletionHandler
    ) {
        do {
            let fetcher = try CrossDeviceSessionFetcher(
                universalLinkURL: universalLinkURL,
                miraclAPI: miraclAPI,
                logger: logger,
                completionHandler: completionHandler
            )

            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func getCrossDeviceSessionFromPushNotificationPayloadCore(
        pushNotificationPayload: [AnyHashable: Any],
        completionHandler: @escaping CrossDeviceSessionCompletionHandler
    ) {
        do {
            let fetcher = try CrossDeviceSessionFetcher(
                pushNotificationPayload: pushNotificationPayload,
                miraclAPI: miraclAPI,
                logger: logger,
                completionHandler: completionHandler
            )

            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func authenticateCrossDeviceSessionCore(
        crossDeviceSession: CrossDeviceSession,
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        let crossDeviceSessionAuthenticator = CrossDeviceSessionAuthenticator(
            user: user,
            crossDeviceSession: crossDeviceSession,
            miraclAPI: miraclAPI,
            userStorage: userStorage,
            crypto: crypto,
            deviceName: deviceName,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                if let error, case AuthenticationError.invalidAuthenticationSession = error {
                    completionHandler(isAuthenticated, AuthenticationError.invalidCrossDeviceSession)
                } else {
                    completionHandler(isAuthenticated, error)
                }
            }
        )

        crossDeviceSessionAuthenticator.authenticate()
    }

    func signCrossDeviceSessionCore(
        crossDeviceSession: CrossDeviceSession,
        user: User,
        didRequestSigningPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping CrossDeviceSigningCompletionHandler
    ) {
        do {
            let signer = try Signer(
                messageHash: Data(hexString: crossDeviceSession.signingHash),
                sessionIdentifier: crossDeviceSession.sessionId,
                user: user,
                miraclAPI: miraclAPI,
                userStorage: userStorage,
                crypto: crypto,
                logger: logger,
                deviceName: deviceName,
                deviceTagManager: deviceTagManager,
                didRequestSigningPinHandler: didRequestSigningPinHandler
            ) { signinResult, error in
                if signinResult != nil {
                    completionHandler(true, nil)
                } else if let error {
                    completionHandler(false, error)
                } else {
                    completionHandler(false, SigningError.signingFail(nil))
                }
            }
            signer.sign()
        } catch {
            logError(error: error, category: .signing)
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    func abortCrossDeviceSessionCore(
        crossDeviceSession: CrossDeviceSession,
        completionHandler: @escaping CrossDeviceSessionAborterCompletionHandler
    ) {
        do {
            let aborter = try CrossDeviceSessionAborter(
                sessionId: crossDeviceSession.sessionId,
                miraclAPI: miraclAPI
            ) { result, error in
                completionHandler(result, error)
            }

            aborter.abort()
        } catch {
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    func signCore(
        message: Data,
        user: User,
        didRequestSigningPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping SigningCompletionHandler
    ) {
        do {
            let signer = try Signer(
                messageHash: message,
                sessionIdentifier: nil,
                user: user,
                miraclAPI: miraclAPI,
                userStorage: userStorage,
                crypto: crypto,
                logger: logger,
                deviceName: deviceName,
                deviceTagManager: deviceTagManager,
                didRequestSigningPinHandler: didRequestSigningPinHandler
            ) { signature, error in
                completionHandler(signature, error)
            }

            signer.sign()
        } catch {
            logError(error: error, category: .signing)
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    func getUsersCore(completionHandler: @escaping GetUsersCompletionHandler) {
        let storage = userStorage
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let allUsers = try storage.all().map { userDTO in
                    userDTO.toUser()
                }

                DispatchQueue.main.async {
                    completionHandler(allUsers, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
    }

    func getUserCore(
        userId: String,
        completionHandler: @escaping GetUserCompletionHandler
    ) {
        let storage = userStorage
        let projectId = projectId

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let user = try storage.getUser(by: userId, projectId: projectId)
                DispatchQueue.main.async {
                    completionHandler(user?.toUser(), nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
    }

    func deleteCore(
        user: User,
        completionHandler: @escaping DeleteUserCompletionHandler
    ) {
        let storage = userStorage
        let completionHandler = completionHandler

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try storage.delete(user: user.toUserDTO())

                DispatchQueue.main.async {
                    completionHandler(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(false, error)
                }
            }
        }
    }
}
