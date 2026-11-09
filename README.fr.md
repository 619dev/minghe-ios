# Minghe iOS

[简体中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Deutsch](README.de.md)

Minghe est un client d’appels SIP pour les serveurs Minghe auto-hébergés. L’application iOS reprend l’interface React et TypeScript d’Android, avec le clavier, l’historique des appels, les réglages d’apparence et huit langues. Capacitor 8.4.1 relie cette interface à Linphone 5.4.129, CallKit et au Trousseau.

## Compiler depuis les sources

Sur macOS, installez Xcode et Node.js 22.12 ou une version ultérieure, puis exécutez ces commandes à la racine du dépôt.

```sh
npm --prefix web ci
npm --prefix web run build
```

Ouvrez `Minghe.xcodeproj` et sélectionnez le schéma `Minghe`. Pour une installation sur un appareil, choisissez votre équipe dans **Signing & Capabilities**. L’application fonctionne à partir d’iOS 17. Recompilez les ressources Web après toute modification de `web/src`.

## Se connecter et appeler

Dans **Compte**, saisissez l’hôte, le poste et le mot de passe SIP, puis connectez-vous. Les réglages par défaut sont TLS sur le port 5061, Digest SHA-256 et SDES-SRTP. Activez MD5 uniquement si le serveur l’exige. Pour un relais ZRTP, sélectionnez ZRTP et comparez le SAS avec votre correspondant. Avec SDES-SRTP, le serveur peut déchiffrer et rechiffrer les médias.

Pour un certificat privé, collez le PEM fourni par votre administrateur ou vérifiez par un canal indépendant l’empreinte SHA-256 affichée avant de l’accepter. L’adresse du serveur doit correspondre au certificat. Les mots de passe enregistrés sont conservés dans le Trousseau.

## Alertes Bark et appels sur écran verrouillé

Installez Bark, autorisez ses notifications et configurez votre poste sur votre serveur auto-hébergé. Dans Minghe, activez **Enregistrer le mot de passe** et **Alertes d’appel Bark**, puis connectez-vous. Le serveur conserve un appel hors ligne pendant 30 secondes au maximum. Touchez la notification pour ouvrir Minghe et recevoir l’appel en attente via CallKit. Un appel établi peut continuer lorsque l’écran est verrouillé.

Minghe fonctionne sans clé APNs ni relais officiel Minghe. Bark transmet l’alerte. L’appel apparaît après l’ouverture de la notification et la réussite de l’enregistrement SIP.

Sur le serveur Minghe, ajoutez la configuration suivante pour le poste 1002. Transmettez la clé d’appareil Bark au processus serveur via la variable d’environnement indiquée.

```toml
[bark."1002"]
endpoint = "https://api.day.app/push"
device_key_env = "MINGHE_BARK_1002_KEY"
```

## App Store

Apple exige une URL publique pour la politique de confidentialité dans App Store Connect et un accès facile à cette politique dans l’application. Un contrat de licence personnalisé est facultatif. Le contrat standard d’Apple s’applique par défaut. Vérifiez les droits de distribution des SDK, la conformité à l’exportation et le fonctionnement sur des appareils avec une version signée.

[Politique de confidentialité (中文 · English)](Minghe/Privacy.md) · [Contrat de licence standard Apple](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) · [Configuration de Bark et liste de vérification (chinois)](RELEASE.md)

[Licence du code source · GNU AGPL v3.0](LICENSE) · [Minghe Android](https://github.com/619dev/minghe-android)
