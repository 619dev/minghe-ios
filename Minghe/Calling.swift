import AVFoundation
import CallKit
import Combine
import linphonesw

struct CallRecord: Codable, Identifiable {
    var id = UUID()
    var peer: String
    var date = Date()
    var incoming: Bool
    var answered = false
}

final class Calling: NSObject, ObservableObject, CXProviderDelegate {
    static let shared = Calling()

    @Published private(set) var settings = SIPSettings()
    @Published private(set) var registration = RegistrationState.None
    @Published private(set) var current: CallRecord?
    @Published private(set) var history: [CallRecord] = []
    @Published private(set) var sas = ""
    @Published private(set) var verified = false
    @Published private(set) var muted = false
    @Published private(set) var online = false
    @Published var error: String?

    var webCallState: String {
        guard let current else { return "idle" }
        if current.answered { return settings.zrtp && !mediaEncrypted ? "securing" : "active" }
        if current.incoming { return "incoming" }
        return call?.state == .OutgoingRinging ? "ringing" : "calling"
    }

    private let defaults = UserDefaults.standard
    private let controller = CXCallController()
    private let provider: CXProvider
    private var sip: SIP?
    private var listener: CoreDelegateStub?
    private var call: Call?
    private var inBackground = false
    private var audioActive = false
    private var mediaEncrypted = false

    private override init() {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = false
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.includesCallsInRecents = false
        provider = CXProvider(configuration: configuration)
        super.init()
        provider.setDelegate(self, queue: .main)
        if let data = defaults.data(forKey: "account"),
           let saved = try? JSONDecoder().decode(SIPSettings.self, from: data) {
            settings = saved
        }
        loadHistory()
        defaults.removeObject(forKey: "voipToken")
    }

    private func loadHistory() {
        let data = defaults.data(forKey: "history-" + settings.scope)
        history = data.flatMap { try? JSONDecoder().decode([CallRecord].self, from: $0) } ?? []
    }

    func foreground() {
        inBackground = false
        if sip == nil, defaults.bool(forKey: "online"), let password = SIPPassword.load(settings) {
            do { try start(settings, password: password) }
            catch { self.error = error.localizedDescription }
        }
        sip?.core.enterForeground()
    }

    func background() {
        inBackground = true
        sip?.core.enterBackground()
        suspendIdleSIP()
    }

    func openBarkReminder(_ url: URL) {
        guard url.absoluteString == "minghe://incoming" else { return }
        foreground()
        if current == nil, registration == .Ok { sip?.account.refreshRegister() }
        if !online { error = String(localized: "Connect your SIP account to receive the call.") }
    }

    private func suspendIdleSIP() {
        guard inBackground, current == nil, settings.barkEnabled else { return }
        stopSIP()
    }

    @MainActor
    func connect(_ settings: SIPSettings, password: String, save: Bool) async {
        do {
            guard current == nil else { throw PhoneError.callFailed }
            try settings.validate()
            let password = password.isEmpty ? SIPPassword.load(settings) ?? "" : password
            guard !password.isEmpty else { throw PhoneError.missingPassword }
            if AVAudioApplication.shared.recordPermission == .undetermined {
                _ = await AVAudioApplication.requestRecordPermission()
            }
            guard current == nil else { throw PhoneError.callFailed }
            let old = self.settings
            // Close the previous SIP connection before replacing the account.
            disconnect()
            if old.host != "", old.authority != settings.authority || old.extensionID != settings.extensionID {
                try SIPPassword.remove(old)
            }
            if save { try SIPPassword.save(password, for: settings) }
            else { try SIPPassword.remove(settings) }
            self.settings = settings
            loadHistory()
            defaults.set(try JSONEncoder().encode(settings), forKey: "account")
            try start(settings, password: password)
            defaults.set(save, forKey: "online")
        } catch { self.error = error.localizedDescription }
    }

    private func start(_ settings: SIPSettings, password: String) throws {
        let engine = try SIP(settings: settings, password: password)
        let delegate = CoreDelegateStub(
            onCallStateChanged: { [weak self] _, call, state, _ in self?.callChanged(call, state: state) },
            onCallEncryptionChanged: { [weak self] _, call, enabled, token in
                self?.encryptionChanged(call, enabled: enabled, token: token)
            },
            onAccountRegistrationStateChanged: { [weak self] _, _, state, _ in self?.registration = state }
        )
        engine.core.addDelegate(delegate: delegate)
        listener = delegate
        sip = engine
        do { try engine.start() }
        catch {
            engine.core.stop()
            sip = nil
            listener = nil
            throw error
        }
        online = true
    }

    func disconnect() {
        defaults.set(false, forKey: "online")
        if let id = current?.id {
            provider.reportCall(with: id, endedAt: nil, reason: .failed)
            finish()
        }
        stopSIP()
    }

    private func stopSIP() {
        sip?.core.stop()
        sip = nil
        listener = nil
        online = false
        registration = .None
    }

    func eraseLocalData() {
        disconnect()
        do { try SIPPassword.remove(settings) }
        catch { self.error = error.localizedDescription; return }
        settings = SIPSettings()
        history = []
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("history-") {
            defaults.removeObject(forKey: key)
        }
        defaults.removeObject(forKey: "account")
        defaults.removeObject(forKey: "voipToken")
        if let support = try? FileManager.default.url(for: .applicationSupportDirectory,
                                                      in: .userDomainMask, appropriateFor: nil, create: false),
           let files = try? FileManager.default.contentsOfDirectory(at: support, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix("zrtp-") {
                do { try FileManager.default.removeItem(at: file) }
                catch { self.error = error.localizedDescription }
            }
        }
    }

    @MainActor
    func dial(_ peer: String) async {
        guard current == nil else { return }
        guard registration == .Ok else {
            error = PhoneError.notRegistered.localizedDescription
            return
        }
        guard SIPSettings.validExtension(peer) else { return }
        guard await AVAudioApplication.requestRecordPermission() else {
            error = String(localized: "Allow microphone access in Settings to make calls.")
            return
        }
        guard current == nil else { return }
        let id = UUID()
        current = CallRecord(id: id, peer: peer, incoming: false)
        request(CXStartCallAction(call: id, handle: CXHandle(type: .generic, value: peer))) { [weak self] in
            guard self?.current?.id == id else { return }
            self?.finish()
        }
    }

    @MainActor
    func answer() async {
        guard let id = current?.id, current?.incoming == true else { return }
        guard await AVAudioApplication.requestRecordPermission() else {
            error = String(localized: "Allow microphone access in Settings to answer calls.")
            return
        }
        guard current?.id == id else { return }
        request(CXAnswerCallAction(call: id))
    }

    func hangUp() {
        guard let id = current?.id else { return }
        request(CXEndCallAction(call: id))
    }

    func toggleMute() {
        guard let id = current?.id else { return }
        request(CXSetMutedCallAction(call: id, muted: !muted))
    }

    func verifySAS() {
        guard mediaEncrypted, !sas.isEmpty, let call else { return }
        call.authenticationTokenVerified = true
        verified = call.authenticationTokenVerified
    }

    private func request(_ action: CXAction, onError: (() -> Void)? = nil) {
        controller.request(CXTransaction(action: action)) { [weak self] error in
            guard let error else { return }
            DispatchQueue.main.async {
                onError?()
                self?.error = error.localizedDescription
            }
        }
    }

    func providerDidReset(_ provider: CXProvider) {
        let active = call
        finish()
        try? active?.terminate()
        audioActive = false
        sip?.core.activateAudioSession(activated: false)
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard current?.id == action.callUUID, let sip else { action.fail(); return }
        sip.core.configureAudioSession()
        prepareMicrophone()
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        do {
            let outgoing = try sip.dial(action.handle.value)
            if current?.id == action.callUUID { call = outgoing }
            action.fulfill()
        } catch {
            action.fail()
            if current?.id == action.callUUID {
                provider.reportCall(with: action.callUUID, endedAt: nil, reason: .failed)
                finish()
            }
            self.error = error.localizedDescription
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard current?.id == action.callUUID, current?.incoming == true,
              let sip, let call, call.state == .IncomingReceived else { action.fail(); return }
        guard AVAudioApplication.shared.recordPermission == .granted else {
            action.fail()
            error = String(localized: "Allow microphone access in Settings to answer calls.")
            failIncoming(id: action.callUUID, reason: .failed)
            return
        }
        sip.core.configureAudioSession()
        prepareMicrophone()
        do {
            try call.acceptWithParams(params: sip.callParameters(call))
            action.fulfill()
        } catch {
            action.fail()
            failIncoming(id: action.callUUID, reason: .failed)
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard current?.id == action.callUUID else { action.fulfill(); return }
        let active = call
        finish()
        if active?.state == .IncomingReceived { try? active?.decline(reason: .Declined) }
        else { try? active?.terminate() }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard current?.id == action.callUUID else { action.fail(); return }
        muted = action.isMuted
        prepareMicrophone()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        audioActive = true
        sip?.core.activateAudioSession(activated: true)
        prepareMicrophone()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        audioActive = false
        sip?.core.activateAudioSession(activated: false)
        prepareMicrophone()
    }

    private func prepareMicrophone() {
        guard let sip else { return }
        sip.core.micEnabled = audioActive && !muted && (!sip.settings.zrtp || mediaEncrypted)
    }

    private func update(_ peer: String?) -> CXCallUpdate {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: peer ?? String(localized: "Unknown extension"))
        return update
    }

    private func callChanged(_ incoming: Call, state: Call.State) {
        if state == .IncomingReceived {
            receiveInvite(incoming)
            return
        }
        guard call === incoming || (call == nil && current?.incoming == false && state == .OutgoingInit),
              let id = current?.id else { return }
        call = incoming
        switch state {
        case .Connected, .StreamsRunning:
            if current?.answered == false {
                current?.answered = true
                if current?.incoming == false { provider.reportOutgoingCall(with: id, connectedAt: nil) }
            }
        case .End, .Error, .Released:
            provider.reportCall(with: id, endedAt: nil, reason: state == .Error ? .failed : .remoteEnded)
            finish()
        default: break
        }
    }

    private func receiveInvite(_ incoming: Call) {
        guard current == nil else {
            try? incoming.decline(reason: .Busy)
            return
        }
        let peer = incoming.remoteAddress?.username ?? ""
        let record = CallRecord(peer: peer, incoming: true)
        current = record
        call = incoming
        provider.reportNewIncomingCall(with: record.id, update: update(peer)) { [weak self] error in
            guard error != nil else { return }
            DispatchQueue.main.async {
                guard self?.current?.id == record.id else { return }
                self?.finish()
                try? incoming.decline(reason: .Declined)
            }
        }
    }

    private func encryptionChanged(_ encrypted: Call, enabled: Bool, token: String) {
        guard call === encrypted, settings.zrtp else { return }
        mediaEncrypted = enabled
        sas = enabled ? token : ""
        verified = enabled && encrypted.authenticationTokenVerified
        prepareMicrophone()
    }

    private func failIncoming(id: UUID, reason: CXCallEndedReason) {
        guard current?.id == id else { return }
        let active = call
        provider.reportCall(with: id, endedAt: nil, reason: reason)
        finish()
        try? active?.terminate()
    }

    private func finish() {
        if let current {
            history.insert(current, at: 0)
            if history.count > 100 { history.removeLast(history.count - 100) }
            defaults.set(try? JSONEncoder().encode(history), forKey: "history-" + settings.scope)
        }
        current = nil
        call = nil
        sas = ""
        verified = false
        muted = false
        mediaEncrypted = false
        prepareMicrophone()
        DispatchQueue.main.async { [weak self] in self?.suspendIdleSIP() }
    }
}
