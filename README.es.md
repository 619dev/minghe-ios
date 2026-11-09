# Minghe iOS

[简体中文](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Deutsch](README.de.md)

Minghe es un cliente de voz SIP para servidores Minghe autohospedados. La aplicación iOS reutiliza la interfaz de Android en React y TypeScript, con teclado de marcación, historial, ajustes de apariencia y ocho idiomas. Capacitor 8.4.1 conecta la interfaz con Linphone 5.4.129, CallKit y el Llavero.

## Compilar desde el código fuente

Instala Xcode y Node.js 22.12 o posterior en macOS y ejecuta estos comandos desde la raíz del repositorio.

```sh
npm --prefix web ci
npm --prefix web run build
```

Abre `Minghe.xcodeproj` y selecciona el esquema `Minghe`. Para instalarlo en un dispositivo, selecciona tu equipo en **Signing & Capabilities**. Se requiere iOS 17 o posterior. Vuelve a compilar los recursos web al modificar `web/src`.

## Conectarse y llamar

En **Cuenta**, introduce el servidor, la extensión y la contraseña SIP, y conéctate. Los valores predeterminados son TLS en el puerto 5061, Digest SHA-256 y SDES-SRTP. Habilita MD5 solo si lo exige el servidor. Selecciona ZRTP si el servidor actúa como relé ZRTP y compara el SAS con la otra persona. Con SDES-SRTP, el servidor puede descifrar y volver a cifrar el audio.

Para un certificado privado, pega el PEM facilitado por el administrador o verifica por un canal independiente la huella SHA-256 que muestra la aplicación antes de aceptarla. La dirección del servidor debe coincidir con el certificado. El Llavero almacena las contraseñas guardadas.

## Avisos de Bark y llamadas con la pantalla bloqueada

Instala Bark, permite sus notificaciones y configura tu extensión en el servidor autohospedado. En Minghe, activa **Guardar contraseña** y **Avisos de llamada de Bark**, y conéctate. El servidor retiene una llamada sin conexión durante un máximo de 30 segundos. Toca la notificación para abrir Minghe y recibir la llamada pendiente mediante CallKit. Las llamadas conectadas pueden continuar con la pantalla bloqueada.

Minghe funciona sin clave APNs ni un relé oficial de Minghe. Bark entrega el aviso. La llamada aparece después de abrir el aviso y completar el registro SIP.

Añade esta configuración al servidor Minghe para la extensión 1002. Proporciona la clave de dispositivo Bark al proceso del servidor mediante la variable de entorno indicada.

```toml
[bark."1002"]
endpoint = "https://api.day.app/push"
device_key_env = "MINGHE_BARK_1002_KEY"
```

## App Store

Apple exige una URL pública de la política de privacidad en App Store Connect y acceso fácil a esa política desde la aplicación. El contrato de licencia personalizado es opcional. Por defecto se aplica el contrato estándar de Apple. Antes de enviar la aplicación, verifica los derechos de distribución de los SDK, los requisitos de exportación y el funcionamiento en dispositivos con una compilación firmada.

[Política de privacidad (中文 · English)](Minghe/Privacy.md) · [Licencia estándar de Apple](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) · [Configuración de Bark y lista de revisión (en chino)](RELEASE.md)

[Licencia del código fuente · GNU AGPL v3.0](LICENSE) · [Minghe Android](https://github.com/619dev/minghe-android)
