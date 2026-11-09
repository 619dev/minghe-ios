import Capacitor
import UIKit

@objc(SipPlugin)
final class SipPlugin: CAPPlugin, CAPBridgedPlugin {
    let identifier = "SipPlugin"
    let jsName = "Sip"
    let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setAppearance", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "discoverCertificate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disconnect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "eraseLocalData", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "dial", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "answer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hangup", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "verify", returnType: CAPPluginReturnPromise)
    ]

    @objc func setAppearance(_ call: CAPPluginCall) {
        Task { @MainActor in
            let style: UIUserInterfaceStyle
            switch call.getString("theme") {
            case "light": style = .light
            case "dark": style = .dark
            default: style = .unspecified
            }
            bridge?.viewController?.view.window?.overrideUserInterfaceStyle = style
            call.resolve()
        }
    }

    @objc func status(_ call: CAPPluginCall) {
        Task { @MainActor in
            let phone = Calling.shared
            var result: [String: Any] = [
                "registration": String(describing: phone.registration),
                "call": phone.webCallState,
                "peer": phone.current?.peer ?? "",
                "sas": phone.sas,
                "verified": phone.verified,
                "history": phone.history.map { item in
                    ["peer": item.peer, "time": item.date.timeIntervalSince1970 * 1000,
                     "incoming": item.incoming, "answered": item.answered] as [String: Any]
                }
            ]
            let settings = phone.settings
            if !settings.host.isEmpty {
                let saved = SIPPassword.load(settings) != nil
                result["account"] = [
                    "host": settings.host, "port": settings.port, "extension": settings.extensionID,
                    "mode": settings.zrtp ? "zrtp" : "sdes", "md5": settings.allowMD5,
                    "certificate": settings.certificate, "bark": settings.barkEnabled,
                    "hasSavedPassword": saved, "savePassword": saved, "language": "system"
                ] as [String: Any]
            }
            if let error = phone.error {
                result["error"] = error
                phone.error = nil
            }
            call.resolve(result)
        }
    }

    @objc func discoverCertificate(_ call: CAPPluginCall) {
        Task { @MainActor in
            let settings = SIPSettings(host: call.getString("host") ?? "", port: call.getInt("port") ?? 0)
            do {
                if let preview = try await CertificatePreview.discover(settings) {
                    call.resolve(["certificate": preview.pem, "fingerprint": preview.fingerprint])
                } else {
                    call.resolve()
                }
            } catch { call.reject(error.localizedDescription) }
        }
    }

    @objc func connect(_ call: CAPPluginCall) {
        guard let input = call.getObject("account"),
              let host = input["host"] as? String, let port = input["port"] as? Int,
              let extensionID = input["extension"] as? String,
              let password = input["password"] as? String else {
            call.reject(PhoneError.invalidAccount.localizedDescription)
            return
        }
        let save = input["savePassword"] as? Bool ?? true
        let settings = SIPSettings(host: host, port: port, extensionID: extensionID,
                                   zrtp: input["mode"] as? String == "zrtp",
                                   allowMD5: input["md5"] as? Bool ?? false,
                                   certificate: input["certificate"] as? String ?? "",
                                   bark: save && (input["bark"] as? Bool == true))
        perform(call) { await $0.connect(settings, password: password, save: save) }
    }

    @objc func disconnect(_ call: CAPPluginCall) { perform(call) { $0.disconnect() } }
    @objc func eraseLocalData(_ call: CAPPluginCall) { perform(call) { $0.eraseLocalData() } }

    @objc func dial(_ call: CAPPluginCall) {
        let peer = call.getString("peer") ?? ""
        guard SIPSettings.validExtension(peer) else {
            call.reject(PhoneError.invalidAccount.localizedDescription)
            return
        }
        perform(call) { await $0.dial(peer) }
    }

    @objc func answer(_ call: CAPPluginCall) { perform(call) { await $0.answer() } }
    @objc func hangup(_ call: CAPPluginCall) { perform(call) { $0.hangUp() } }
    @objc func verify(_ call: CAPPluginCall) { perform(call) { $0.verifySAS() } }

    private func perform(_ call: CAPPluginCall, action: @escaping @MainActor (Calling) async -> Void) {
        Task { @MainActor in
            let phone = Calling.shared
            phone.error = nil
            await action(phone)
            if let error = phone.error {
                phone.error = nil
                call.reject(error)
            } else {
                call.resolve()
            }
        }
    }
}
