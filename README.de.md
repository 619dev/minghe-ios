# Minghe iOS

[简体中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Deutsch](README.de.md)

Minghe ist ein SIP-Sprachclient für selbst gehostete Minghe-Server. Die iOS-App übernimmt die React- und TypeScript-Oberfläche von Android mit Wähltastatur, Anrufliste, Darstellungseinstellungen und acht Sprachen. Capacitor 8.4.1 verbindet die Oberfläche mit Linphone 5.4.129, CallKit und dem Schlüsselbund.

## Aus dem Quellcode bauen

Installiere unter macOS Xcode und Node.js 22.12 oder neuer. Führe im Stammverzeichnis des Repositorys folgende Befehle aus.

```sh
npm --prefix web ci
npm --prefix web run build
```

Öffne `Minghe.xcodeproj` und wähle das Schema `Minghe`. Wähle für Geräte-Builds unter **Signing & Capabilities** dein Entwicklerteam. Die App unterstützt iOS 17 und neuer. Erstelle die Web-Ressourcen nach Änderungen in `web/src` neu.

## Verbinden und anrufen

Gib unter **Konto** den Server, die Nebenstelle und das SIP-Passwort ein und gehe online. Standardmäßig verwendet Minghe TLS auf Port 5061, SHA-256 Digest und SDES-SRTP. Aktiviere MD5 nur, wenn der Server es verlangt. Wähle für einen ZRTP-Relay ZRTP und vergleiche den SAS-Code mit der Gegenstelle. Mit SDES-SRTP kann der Server Medien entschlüsseln und erneut verschlüsseln.

Füge bei einem privaten Zertifikat die PEM-Datei deines Administrators ein oder prüfe den angezeigten SHA-256-Fingerabdruck vor dem Bestätigen über einen unabhängigen Kanal. Die Serveradresse muss zum Zertifikat passen. Gespeicherte Passwörter liegen im Schlüsselbund.

## Bark-Hinweise und Anrufe bei gesperrtem Bildschirm

Installiere Bark, erlaube Mitteilungen und konfiguriere deine Nebenstelle auf dem selbst gehosteten Server. Aktiviere in Minghe **Passwort speichern** und **Bark-Anrufhinweise** und gehe online. Der Server hält einen Anruf bei fehlender SIP-Verbindung bis zu 30 Sekunden vor. Tippe auf den Hinweis, um Minghe zu öffnen und den wartenden Anruf über CallKit anzunehmen. Ein verbundenes Gespräch kann bei gesperrtem Bildschirm weiterlaufen.

Minghe benötigt weder einen APNs-Schlüssel noch einen offiziellen Minghe-Relay. Bark stellt den Hinweis zu. Nach dem Öffnen des Hinweises und der erfolgreichen SIP-Registrierung erscheint der Anruf.

Ergänze auf dem Minghe-Server folgende Konfiguration für die Nebenstelle 1002. Übergib den Bark-Geräteschlüssel über die angegebene Umgebungsvariable an den Serverprozess.

```toml
[bark."1002"]
endpoint = "https://api.day.app/push"
device_key_env = "MINGHE_BARK_1002_KEY"
```

## App Store

Apple verlangt eine öffentliche URL zur Datenschutzerklärung in App Store Connect und einen leicht auffindbaren Zugriff in der App. Eine eigene EULA ist optional. Standardmäßig gilt Apples Standardlizenz. Prüfe vor der Einreichung die Vertriebsrechte der SDKs, die Exportvorgaben und die Funktion auf Geräten mit signiertem Build.

[Datenschutzerklärung (中文 · English)](Minghe/Privacy.md) · [Apple-Standardlizenz](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) · [Bark-Konfiguration und Einreichungscheckliste (Chinesisch)](RELEASE.md)

[Quellcodelizenz · GNU AGPL v3.0](LICENSE) · [Minghe Android](https://github.com/619dev/minghe-android)
