import CryptoKit
import Foundation
import Network
import Security
import linphonesw
import os

struct SIPSettings: Codable, Equatable {
    var host = ""
    var port = 5061
    var extensionID = ""
    var zrtp = false
    var allowMD5 = false
    var certificate = ""
    var bark: Bool?

    var barkEnabled: Bool { bark == true }

    var authority: String { "\(host):\(port)" }

    var scope: String {
        SHA256.hash(data: Data("\(extensionID)@\(authority)".utf8))
            .map { String(format: "%02x", $0) }.joined()
    }

    var endpoint: NWEndpoint.Port? {
        guard host.range(of: #"^[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$"#,
                         options: .regularExpression) != nil,
              (1...65535).contains(port) else { return nil }
        return NWEndpoint.Port(rawValue: UInt16(port))
    }

    func validate() throws {
        guard endpoint != nil, Self.validExtension(extensionID) else {
            throw PhoneError.invalidAccount
        }
        if !certificate.isEmpty {
            let base64 = certificate.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                .components(separatedBy: .whitespacesAndNewlines).joined()
            guard let der = Data(base64Encoded: base64),
                  SecCertificateCreateWithData(nil, der as CFData) != nil else {
                throw PhoneError.invalidCertificate
            }
        }
    }

    static func validExtension(_ value: String) -> Bool {
        value.range(of: #"^[A-Za-z0-9_.+-]{1,64}$"#, options: .regularExpression) != nil
    }
}

enum PhoneError: LocalizedError {
    case invalidAccount, invalidCertificate, missingPassword, keychain, notRegistered, callFailed

    var errorDescription: String? {
        switch self {
        case .invalidAccount: String(localized: "Enter a valid server, TLS port and extension.")
        case .invalidCertificate: String(localized: "Paste one trusted PEM certificate.")
        case .missingPassword: String(localized: "Enter the SIP password.")
        case .keychain: String(localized: "The SIP password could not be stored securely.")
        case .notRegistered: String(localized: "Connect your SIP account first.")
        case .callFailed: String(localized: "The call could not be connected.")
        }
    }
}

enum SIPPassword {
    private static func query(_ settings: SIPSettings) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "app.fm619.minghe.sip",
         kSecAttrAccount as String: "\(settings.extensionID)@\(settings.authority)"]
    }

    static func load(_ settings: SIPSettings) -> String? {
        var request = query(settings)
        request[kSecReturnData as String] = true
        var result: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ password: String, for settings: SIPSettings) throws {
        let key = query(settings)
        let values: [String: Any] = [
            kSecValueData as String: Data(password.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updated = SecItemUpdate(key as CFDictionary, values as CFDictionary)
        if updated == errSecSuccess { return }
        guard updated == errSecItemNotFound,
              SecItemAdd(key.merging(values) { _, new in new } as CFDictionary, nil) == errSecSuccess else {
            throw PhoneError.keychain
        }
    }

    static func remove(_ settings: SIPSettings) throws {
        let result = SecItemDelete(query(settings) as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else { throw PhoneError.keychain }
    }
}

final class SIP {
    let core: Core
    let account: Account
    let settings: SIPSettings
    private let encryption: MediaEncryption

    init(settings: SIPSettings, password: String) throws {
        self.settings = settings
        encryption = settings.zrtp ? .ZRTP : .SRTP
        let factory = Factory.Instance
        let support = try FileManager.default.url(for: .applicationSupportDirectory,
                                                  in: .userDomainMask, appropriateFor: nil, create: true)
        // Keep the SIP password out of the SDK configuration file.
        core = try factory.createCore(configPath: nil, factoryConfigPath: nil, systemContext: nil)
        core.setUserAgent(name: "Minghe", version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        core.pushNotificationEnabled = false
        core.verifyServerCertificates(yesno: true)
        core.verifyServerCn(yesno: true)
#if targetEnvironment(simulator)
        core.callkitEnabled = false
#else
        core.callkitEnabled = true
#endif
        core.limeX3DhEnabled = false
        core.keepAliveEnabled = true
        core.ipv6Enabled = false
        core.videoCaptureEnabled = false
        core.videoDisplayEnabled = false
        core.sessionExpiresEnabled = false
        core.avpfMode = .Disabled
        core.maxCalls = 1
        core.nativeRingingEnabled = false
        core.ring = nil
        core.zrtpGoClearEnabled = false
        core.zrtpSecretsFile = support.appendingPathComponent("zrtp-\(settings.scope)").path
        core.natPolicy = try core.createNatPolicy()
        if !settings.certificate.isEmpty { core.rootCaData = settings.certificate + "\n" }
        let digest = try factory.createDigestAuthenticationPolicy()
        digest.allowNoQop = false
        digest.allowMd5 = settings.allowMD5
        core.digestAuthenticationPolicy = digest
        let transports = try factory.createTransports()
        transports.udpPort = 0
        transports.tcpPort = 0
        transports.tlsPort = -1
        try core.setTransports(newValue: transports)

        let params = try core.createAccountParams()
        try params.setIdentityaddress(newValue: factory.createAddress(addr: "sip:\(settings.extensionID)@\(settings.host)"))
        try params.setServeraddress(newValue: factory.createAddress(addr: "sip:\(settings.authority);transport=tls"))
        let route = try factory.createAddress(addr: "sip:\(settings.authority);transport=tls;lr")
        try params.setRoutesaddresses(newValue: [route])
        params.transport = .Tls
        params.pushNotificationAllowed = false
        params.remotePushNotificationAllowed = false
        params.expires = 300
        params.registerEnabled = true
        core.addAuthInfo(info: try factory.createAuthInfo(username: settings.extensionID, userid: nil,
                                                          passwd: password, ha1: nil, realm: nil, domain: settings.host))
        account = try core.createAccount(params: params)
    }

    func start() throws {
        try core.start()
        guard core.isMediaEncryptionSupported(menc: encryption) else { throw PhoneError.callFailed }
        try core.setMediaencryption(newValue: encryption)
        core.mediaEncryptionMandatory = true
        if !settings.zrtp { core.srtpCryptoSuites = "AES_CM_128_HMAC_SHA1_80" }
        core.disableChat(denyReason: .NotAcceptable)
        for codec in core.audioPayloadTypes {
            _ = codec.enable(enabled: codec.mimeType == "PCMU" || codec.mimeType == "PCMA")
        }
        try core.addAccount(account: account)
        core.defaultAccount = account
    }

    func callParameters(_ call: Call?) throws -> CallParams {
        let params = try core.createCallParams(call: call)
        params.account = account
        params.videoEnabled = false
        params.mediaEncryption = encryption
        return params
    }

    func dial(_ peer: String) throws -> Call {
        guard SIPSettings.validExtension(peer), account.state == .Ok else { throw PhoneError.notRegistered }
        let address = try Factory.Instance.createAddress(addr: "sip:\(peer)@\(settings.authority);transport=tls")
        guard let call = core.inviteAddressWithParams(addr: address, params: try callParameters(nil)) else {
            throw PhoneError.callFailed
        }
        return call
    }
}

struct CertificatePreview: Identifiable {
    var id: String { fingerprint }
    let pem: String
    let fingerprint: String

    static func discover(_ settings: SIPSettings) async throws -> CertificatePreview? {
        guard let port = settings.endpoint else { throw PhoneError.invalidAccount }
        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "app.fm619.minghe.certificate")
            let tls = NWProtocolTLS.Options()
            let pending = OSAllocatedUnfairLock(initialState: Optional<NWConnection>.none)
            @Sendable func finish(_ result: Result<CertificatePreview?, Error>) {
                let connection = pending.withLock { active in
                    let connection = active
                    active = nil
                    return connection
                }
                guard let connection else { return }
                connection.stateUpdateHandler = nil
                connection.cancel()
                continuation.resume(with: result)
            }
            sec_protocol_options_set_verify_block(tls.securityProtocolOptions, { _, trust, complete in
                // This connection is for discovery only. Never complete a TLS session or send SIP data.
                let serverTrust = sec_trust_copy_ref(trust).takeRetainedValue()
                SecTrustSetNetworkFetchAllowed(serverTrust, false)
                if SecTrustEvaluateWithError(serverTrust, nil) {
                    complete(false)
                    finish(.success(nil))
                    return
                }
                let certificates = SecTrustCopyCertificateChain(serverTrust)
                let certificate = (certificates as? [SecCertificate])?.first
                complete(false)
                guard let certificate else { finish(.failure(PhoneError.invalidCertificate)); return }
                let der = SecCertificateCopyData(certificate) as Data
                let body = der.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
                let fingerprint = SHA256.hash(data: der).map { String(format: "%02X", $0) }.joined(separator: ":")
                let pem = "-----BEGIN CERTIFICATE-----\n\(body)\n-----END CERTIFICATE-----"
                finish(.success(CertificatePreview(pem: pem, fingerprint: fingerprint)))
            }, queue)
            let probe = NWConnection(host: NWEndpoint.Host(settings.host), port: port,
                                     using: NWParameters(tls: tls))
            pending.withLock { $0 = probe }
            probe.stateUpdateHandler = { state in
                if case let .failed(error) = state { finish(.failure(error)) }
            }
            let timeout = DispatchWorkItem {
                finish(.failure(URLError(.timedOut)))
            }
            queue.asyncAfter(deadline: .now() + 8, execute: timeout)
            probe.start(queue: queue)
        }
    }
}
