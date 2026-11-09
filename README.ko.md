# Minghe iOS

[简体中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Deutsch](README.de.md)

Minghe는 자체 운영하는 Minghe 서버용 SIP 음성 통화 클라이언트입니다. iOS 버전은 Android의 React 및 TypeScript 화면을 가져와 다이얼 패드, 통화 기록, 화면 모드와 8개 언어를 제공합니다. Capacitor 8.4.1을 통해 Linphone 5.4.129, CallKit, 키체인을 사용합니다.

## 소스에서 빌드

Xcode와 Node.js 22.12 이상이 설치된 macOS에서 저장소 루트의 다음 명령을 실행합니다.

```sh
npm --prefix web ci
npm --prefix web run build
```

`Minghe.xcodeproj`를 열고 `Minghe` 스킴을 선택합니다. 실제 기기용 빌드에서는 **Signing & Capabilities**에서 개발 팀을 지정합니다. iOS 17 이상을 지원합니다. `web/src`를 수정한 뒤 웹 리소스를 다시 빌드하세요.

## 연결 및 통화

**계정**에서 서버 호스트, 내선 번호, SIP 비밀번호를 입력하고 온라인 상태로 전환합니다. 기본값은 TLS 포트 5061, SHA-256 Digest, SDES-SRTP입니다. 서버에서 요구하는 경우에만 MD5를 활성화합니다. ZRTP 릴레이를 사용하는 경우 ZRTP를 선택하고 상대방과 SAS를 대조합니다. SDES-SRTP에서는 서버가 미디어를 복호화하고 다시 암호화할 수 있습니다.

관리자가 제공한 PEM 인증서를 붙여 넣거나 앱에 표시된 SHA-256 지문을 별도 경로로 확인한 뒤 수락합니다. 서버 주소는 인증서와 일치해야 합니다. 저장한 비밀번호는 키체인에 보관합니다.

## Bark 알림 및 잠금 화면 통화

Bark를 설치하고 알림을 허용한 뒤 자체 서버에 내선 번호를 설정합니다. Minghe에서 **비밀번호 저장**과 **Bark 수신 알림**을 활성화하고 온라인 상태로 전환합니다. 서버는 오프라인 수신 통화를 최대 30초간 보류합니다. 알림을 눌러 Minghe를 열면 대기 중인 통화를 CallKit으로 받을 수 있습니다. 연결된 통화는 화면이 잠겨도 계속됩니다.

Minghe에는 APNs 키나 공식 중계 서버가 필요하지 않습니다. Bark가 알림을 전달하며, 사용자가 알림을 열고 SIP 등록에 성공한 뒤 수신 화면이 표시됩니다.

Minghe 서버에서 내선 1002를 다음과 같이 설정하고, 지정한 환경 변수로 Bark 기기 키를 서버 프로세스에 전달합니다.

```toml
[bark."1002"]
endpoint = "https://api.day.app/push"
device_key_env = "MINGHE_BARK_1002_KEY"
```

## App Store

App Store Connect에 공개 개인정보 처리방침 URL을 등록하고 앱에서도 쉽게 열 수 있도록 해야 합니다. 자체 EULA는 선택 사항이며 기본적으로 Apple 표준 EULA가 적용됩니다. 제출 전에 SDK 배포 권한, 암호화 수출 요건, 서명된 실제 기기에서의 동작을 확인하세요.

[개인정보 처리방침 (中文 · English)](Minghe/Privacy.md) · [Apple 표준 사용권 계약](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) · [Bark 설정 및 심사 체크리스트(중국어)](RELEASE.md)

[소스 라이선스 · GNU AGPL v3.0](LICENSE) · [Minghe Android](https://github.com/619dev/minghe-android)
