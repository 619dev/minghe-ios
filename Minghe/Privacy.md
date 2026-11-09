**Minghe iOS Privacy Policy**

Minghe is a SIP voice client for a server you choose. It does not create a Minghe cloud account or send analytics, advertising identifiers or recordings to the app developer.

**On your device**

The app stores your SIP settings, optional trusted certificate and up to 100 recent calls per account. Call history includes the other extension, time, direction and whether the call connected. If you choose to save the SIP password, the app stores it in the device-only Keychain. ZRTP stores peer verification material locally. Minghe uses the microphone during calls and does not record calls. Language and appearance preferences are stored on the device. CallKit receives the peer extension to display the system call interface.

**Your SIP server, Bark and Apple**

The app sends your SIP extension, Digest authentication data, call signaling and encrypted media to the server you configure. In SDES-SRTP mode the server can decrypt and re-encrypt media. If your SIP server administrator enables Bark reminders, that server sends a generic incoming-call reminder and the configured Bark device key to its chosen Bark endpoint. The reminder contains a link to open Minghe. Bark and Apple handle delivery. Your server administrator controls server-side logging, retention, sharing and deletion. Contact your administrator for that server’s policy and to exercise rights over data it holds. Apple processes push delivery under its [Privacy Policy](https://www.apple.com/legal/privacy/).

**Your controls**

To stop Bark reminders, ask your server administrator to remove the Bark configuration for your extension. Use About → Erase local data to remove the saved account, credentials, ZRTP verification and call history from this device. Use iOS Settings to change microphone or local-network access. Deleting local data does not remove information already held by your SIP server.

**Contact**

For app privacy requests, contact the Minghe maintainer through [minghe.mobile](https://minghe.mobile).

**Minghe iOS 隐私政策**

Minghe 是连接到您所选服务器的 SIP 语音客户端。应用不创建 Minghe 云账户，也不向应用开发者发送分析数据、广告标识符或录音。

**设备上的数据**

应用在设备上保存 SIP 设置、您选择信任的证书，以及每个账户最多 100 条最近通话记录，包括对方分机、时间、通话方向和是否接通。选择保存密码时，密码存入本机钥匙串。ZRTP 的对端核验资料存放于设备上。应用在通话时使用麦克风，且不录制通话。语言和外观偏好保存在本机。CallKit 会接收对端分机号，以显示系统通话界面。

**SIP 服务器、Bark 与 Apple**

应用向您配置的服务器发送 SIP 分机、Digest 认证信息、呼叫信令和加密媒体。使用 SDES-SRTP 时，服务器可以解密并重新加密语音。如果服务器管理员启用了 Bark 提醒，该服务器会把通用来电提醒及已配置的 Bark 设备密钥发送至管理员选择的 Bark 服务。提醒附有打开 Minghe 的链接。通知由 Bark 和 Apple 投递。服务器管理员决定服务器端的日志、保留、共享和删除方式。有关服务器政策和数据权利，请联系管理员。Apple 依照其[隐私政策](https://www.apple.com/legal/privacy/)处理推送投递。

**您的选择**

要停止接收 Bark 提醒，请让服务器管理员移除您的分机 Bark 配置。可在「关于」中清除本机保存的账户、密码、ZRTP 核验资料和通话记录，或在系统设置中修改麦克风及本地网络访问权限。清除本机数据后，服务器端数据仍由服务器管理员管理。

**联系方式**

应用隐私相关请求可通过 [minghe.mobile](https://minghe.mobile) 联系 Minghe 维护者。
