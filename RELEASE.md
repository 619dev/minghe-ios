# 后台来电对接与 App Store 提审

[返回中文说明](README.md) · [English README](README.en.md)

Apple 规则核对日期为 2026 年 11 月 10 日。

## Bark 来电提醒

在 iPhone 安装 Bark 并允许其发送通知。在自建 Minghe 服务端配置希望接收提醒的分机。服务端会向指定的 Bark HTTPS 地址直接请求，可选官方 Bark 地址或自选实例。以下以 1002 分机为例。

```toml
[bark."1002"]
endpoint = "https://api.day.app/push"
device_key_env = "MINGHE_BARK_1002_KEY"
```

将 Bark 设备密钥作为 `MINGHE_BARK_1002_KEY` 环境变量传给服务端进程。Docker Compose 部署应将变量加入服务的 `environment`；容器镜像已加入 curl，宿主机部署也需要 curl。服务端将密钥放在 HTTPS 请求体中。

在 Minghe iOS 的「账户」勾选「保存密码」，在「高级设置」打开「Bark 来电提醒」，然后上线。来电提醒只在被叫没有可用 SIP 连接时发出。用户点击通知的 `minghe://incoming` 打开应用并恢复已保存账户的 SIP 注册。注册后服务端转发仍在等待的 INVITE。有效窗口为 30 秒，主叫取消后待接呼叫会撤销。已经发出的 Bark 通知可能仍可见。

显式下线后应用需要手动上线。要停止提醒，请让服务端管理员移除对应分机配置。Minghe 无需 APNs 密钥，Bark 自身使用 Apple 推送服务投递通知。[Bark HTTP API](https://github.com/Finb/bark-server/blob/master/docs/API_V2.md)

## App Store 提交条件

- **签名和构建**。用 Xcode 26 或更新版本和 iOS 26 或更新 SDK 构建并签名归档，通过 Xcode Organizer 上传。App 的最低运行版本仍是 iOS 17。App Store Connect 需补齐商店说明、截图、年龄分级、支持 URL 和审核联系信息。[Apple SDK 最低要求](https://developer.apple.com/news/upcoming-requirements/?id=04282026a) · [App Store Connect 应用信息](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- **审核访问**。提供可从外网访问的 TLS 演示服务器、两个预建测试分机和复现步骤。审核期间保持服务器在线。商店描述和审核备注应区分已接通电话的后台音频与 Bark 离线提醒，说明 Bark 是可选功能，点击提醒才打开 Minghe 接收待接来电。[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **发行地区**。如果选择中国大陆商店，单独核对当地对应用的备案、许可及 VoIP 功能要求，并在 App Store Connect 按实际类别提交适用资料。[Apple 中国大陆商店资料要求](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)

## 权限、协议与隐私

- **权限**。麦克风在启用 SIP 电话时请求，拒绝后仍可查看和配置账户。连接到局域网服务器时由 iOS 请求本地网络访问。离线提醒由 Bark 投递，接收到 SIP INVITE 后由 CallKit 提供来电界面。Minghe 只声明实际通话的后台音频模式。[App Review Guidelines 2.5.4](https://developer.apple.com/app-store/review/guidelines/#software-requirements)
- **隐私政策必须提供**。应用内「关于」已提供[中英文隐私政策](Minghe/Privacy.md)。发布者需要核实政策所述运营方式和联系方式，将政策发布到公开网页，再把该 URL 填入 App Store Connect。根据实际审核服务器、推送服务、日志留存和 SDK 行为填写 App Privacy。工程的隐私清单声明本地 UserDefaults 的使用理由。当前无签名 Release 产物包含应用自身以及 Capacitor 和 Cordova 的隐私清单。Capacitor 在 Apple 的指定 SDK 名单上，签名归档时应复核实际打包的 SDK 清单和二进制 SDK 签名要求，并根据实际运营填写 App Privacy。[Apple 第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements/)[App Review Guidelines 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy) · [App Privacy 数据定义](https://developer.apple.com/app-store/app-privacy-details/)
- **自定义 EULA 可选**。App Store 在没有自定义协议时适用 Apple 标准 EULA。应用内已链接 Apple 标准 EULA。仅在发布者确实需要自行约定条款时编写自定义 EULA，并按 Apple 对自定义协议的最低条款要求提交。App 的开源许可、Linphone SDK 的分发许可和店内 EULA 是分别需要核对的事项。发布前确认所用 SDK 发行物的 AGPL 对应源码和许可义务与计划采用的商店分发条款兼容，或取得适用于该分发方式的授权。[Apple EULA 设置](https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement) · [Linphone SDK 许可](https://wiki.linphone.org/xwiki/wiki/public/view/Lib/#HLicense)
- **账户删除规则**。目前 App 只连接管理员预建的 SIP 分机，没有注册账户功能。「清除本地数据」删除设备上的配置和通话记录。以后若加入创建账户功能，应提供应用内发起账户删除的入口。[Apple 账户删除要求](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- **加密出口申报**。项目使用 Linphone 的 TLS、SRTP 和 ZRTP。按发行地区在 App Store Connect 回答加密出口合规问题，并按需提交资料。[Apple 加密出口合规](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)

## 提审前真机验收

- 在两台真机验证注册、前台呼入/呼出、双向声音、挂断、拒接、取消、并发占线、来电未及时送达，以及 SDES-SRTP 和 ZRTP SAS。
- 用已签名的真机版本测试 Bark 提醒点击跳转、SIP 重注册、超时及主叫提前取消。在通话中锁屏、切换网络，检查音频与挂断行为。测试注销、麦克风拒绝、设备重启后首次解锁和私有 TLS 证书。
