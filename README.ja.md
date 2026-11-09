# Minghe iOS

[简体中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Deutsch](README.de.md)

Minghe は、自分で運用する Minghe サーバー向けの SIP 音声通話クライアントです。iOS 版は Android 版の React・TypeScript UI を移植し、ダイヤルパッド、通話履歴、外観設定、8 言語に対応しています。Capacitor 8.4.1 を通じて Linphone 5.4.129、CallKit、キーチェーンを利用します。

## ソースからビルド

Xcode と Node.js 22.12 以降を用意し、リポジトリのルートで以下を実行します。

```sh
npm --prefix web ci
npm --prefix web run build
```

`Minghe.xcodeproj` を開き、`Minghe` スキームを選択します。実機では **Signing & Capabilities** で開発チームを指定してください。iOS 17 以降に対応します。`web/src` を変更したら Web アセットを再ビルドします。

## 接続と通話

**アカウント**でサーバーのホスト名、内線番号、SIP パスワードを入力してオンラインにします。既定値は TLS ポート 5061、SHA-256 Digest、SDES-SRTP です。MD5 はサーバーが要求する場合だけ有効にしてください。ZRTP リレーでは ZRTP を選び、通話相手と SAS を照合します。SDES-SRTP ではサーバーがメディアを復号・再暗号化できます。

プライベート証明書は管理者から受け取った PEM を貼り付けるか、表示された SHA-256 フィンガープリントを別経路で確認してから受け入れます。サーバーのアドレスは証明書と一致する必要があります。保存したパスワードはキーチェーンに格納されます。

## Bark の着信通知とロック中の通話

Bark をインストールして通知を許可し、自分で運用するサーバーで内線を設定します。Minghe で **パスワードを保存**と **Bark 着信通知**を有効にしてオンラインにします。サーバーはオフライン時の着信を最大 30 秒保留します。通知をタップして Minghe を開くと、待機中の着信を CallKit で受けられます。接続済みの通話は画面ロック中も続けられます。

Minghe に APNs キーや公式中継サーバーは不要です。通知は Bark が配信します。通知を開いて SIP 登録が成功すると着信画面が表示されます。

Minghe サーバーで内線 1002 を次のように設定し、指定した環境変数で Bark のデバイスキーをサーバープロセスに渡します。

```toml
[bark."1002"]
endpoint = "https://api.day.app/push"
device_key_env = "MINGHE_BARK_1002_KEY"
```

## App Store

App Store Connect には公開されたプライバシーポリシーの URL が必要です。アプリ内からも容易に参照できるようにします。独自の EULA は任意で、既定では Apple の標準 EULA が適用されます。提出前に SDK の配布権、暗号輸出要件、署名済み実機での動作を確認してください。

[プライバシーポリシー (中文 · English)](Minghe/Privacy.md) · [Apple 標準使用許諾契約](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) · [Bark の設定と審査チェックリスト（中国語）](RELEASE.md)

[ソースライセンス · GNU AGPL v3.0](LICENSE) · [Minghe Android](https://github.com/619dev/minghe-android)
