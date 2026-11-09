# Minghe iOS

[简体中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Deutsch](README.de.md)

Minghe is a SIP voice client for self-hosted Minghe servers. The iOS app reuses Android’s React and TypeScript interface, including the dial pad, call history, appearance settings and eight languages. Capacitor 8.4.1 connects the interface to Linphone 5.4.129, CallKit and Keychain.

## Build from source

Use macOS with Xcode and Node.js 22.12 or later. Run these commands from the repository root.

```sh
npm --prefix web ci
npm --prefix web run build
```

Open `Minghe.xcodeproj`, select the `Minghe` scheme and choose your development team under **Signing & Capabilities** for device builds. The app supports iOS 17 and later. Rebuild the web assets after editing `web/src`.

## Connect and call

In **Account**, enter the server host, extension and SIP password, then go online. The defaults are TLS port 5061, SHA-256 Digest and SDES-SRTP. Enable MD5 only if your server requires it. Select ZRTP for a ZRTP relay and compare the SAS with the other caller. In SDES-SRTP mode the server can decrypt and re-encrypt media.

For a private certificate, paste the PEM supplied by your administrator or independently verify the SHA-256 fingerprint shown by the app before accepting it. The server address must match the certificate. Saved passwords are stored in Keychain.

## Bark reminders and locked-screen calls

Install Bark, allow its notifications and configure your extension on your self-hosted server. In Minghe, enable **Save password** and **Bark call reminders**, then go online. The server holds an offline call for up to 30 seconds. Tap the Bark notification to open Minghe and receive the pending call through CallKit. Connected calls can continue with the screen locked.

Minghe needs no APNs key or Minghe-operated relay. Bark delivers the reminder. The incoming call appears after you open the reminder and SIP registration succeeds.

On the Minghe server, set the following for extension 1002. Pass the Bark device key to the server process through the named environment variable.

```toml
[bark."1002"]
endpoint = "https://api.day.app/push"
device_key_env = "MINGHE_BARK_1002_KEY"
```

## App Store

Apple requires a public Privacy Policy URL in App Store Connect and easy access to the policy in the app. A custom EULA is optional. Apple’s standard EULA applies by default. Check SDK distribution rights, export compliance and signed-device testing before submission.

[Privacy policy (中文 · English)](Minghe/Privacy.md) · [Apple standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) · [Bark setup and submission checklist (Chinese)](RELEASE.md)

[Source license · GNU AGPL v3.0](LICENSE) · [Minghe Android](https://github.com/619dev/minghe-android)
