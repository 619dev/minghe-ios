# Minghe iOS

[简体中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Deutsch](README.de.md)

Minghe 是面向自建 Minghe 服务端的 SIP 语音客户端。iOS 版直接沿用 Android 的 React + TypeScript 前端，包括拨号盘、账户设置、主题、八种界面语言和通话记录。前端源文件在 `web/src`。Capacitor 8.4.1 在 iOS 上运行页面，`Minghe/SipPlugin.swift` 将前端的 `Sip` 接口接到 Linphone 5.4.129、CallKit 和 Keychain。

## 构建与连接

安装 Node.js 22.12+，在工程根目录执行以下命令。

```sh
npm --prefix web ci
npm --prefix web run build
```

前端构建生成 `Minghe/public`，供 Xcode 打包。改动前端后重新执行构建命令。

1. 用 Xcode 打开 `Minghe.xcodeproj`，选择 `Minghe` scheme。最低系统为 iOS 17。首次构建时，Swift Package Manager 会下载固定版本的 Capacitor 和 Linphone SDK。
2. 安装到 iPhone 时，在 **Signing & Capabilities** 选择自己的开发团队。
3. 在 **账户** 填写服务器地址、TLS 端口、分机和密码后上线。默认端口为 5061，默认媒体模式为 SDES-SRTP。使用 ZRTP relay 的服务器需要选择 ZRTP。Minghe 服务端另有需要专用签名 SDP 的 DTLS-SRTP 配置，该配置与本客户端的两种媒体模式不同。SDES-SRTP 下服务端可解密并重新加密语音。
4. 私有证书应由管理员提供。未导入证书且系统无法验证服务端证书时，应用会显示其 SHA-256 指纹。请向管理员独立核对后再确认。SIP TLS 会校验证书及服务器名称。地址应与证书标识匹配。

无签名构建命令

```sh
xcodebuild -project Minghe.xcodeproj -scheme Minghe \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## 锁屏来电和通话

已接通的电话通过 CallKit 和后台音频继续。启用 Bark 模式后，Minghe 在空闲时进入后台会关闭 SIP 连接，已有通话结束后也会释放连接。配置了 Bark 的自建服务端会暂存离线来电并发送提醒。点开提醒后，Minghe 重新注册，服务端转发待接呼叫，再由 CallKit 提供接听界面。

使用 Bark 需要保存 SIP 密码、安装 Bark 并配置对应分机。服务端最多暂存来电 30 秒。Minghe 客户端和自建服务端不配置 APNs 密钥，也不依赖 Minghe 官方中转。通知由 Bark 投递，需要用户点开后才能接收 SIP 来电。

## App Store

App Store Connect 必须填写公开的隐私政策 URL，应用内也必须有易于找到的政策入口。自定义用户许可协议可选，默认适用 Apple 标准 EULA。提交前需核对 SDK 分发许可、加密出口申报，并完成签名真机验收。

[隐私政策（中文 · English）](Minghe/Privacy.md) · [Apple 标准 EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) · [服务端对接与上架检查](RELEASE.md)

Minghe 源码采用 [GNU AGPL v3.0](LICENSE)。图标沿用 [Minghe Android](https://github.com/619dev/minghe-android)。
