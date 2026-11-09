import Capacitor
import SwiftUI

@main
struct MingheApp: App {
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            WebApp()
                .ignoresSafeArea()
                .onOpenURL { Calling.shared.openBarkReminder($0) }
                .onChange(of: phase, initial: true) { _, phase in
                    if phase == .active { Calling.shared.foreground() }
                    if phase == .background { Calling.shared.background() }
                }
        }
    }
}

private struct WebApp: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MingheBridge { MingheBridge() }
    func updateUIViewController(_ controller: MingheBridge, context: Context) {}
}

private final class MingheBridge: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(SipPlugin())
    }
}
