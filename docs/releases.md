# Publicación de versiones

Stronger se distribuye como APK descargable desde las *releases* del
repositorio. No está en Google Play, así que el APK se instala de forma manual
("orígenes desconocidos") y **no se actualiza solo**: cada versión nueva la
descarga el usuario a mano.

El workflow [`release.yml`](../.github/workflows/release.yml) hace todo el
trabajo: se dispara al empujar una etiqueta `vX.Y.Z`, valida, compila, firma y
publica el APK en la release de GitHub.

## Preparación (una sola vez)

### 1. Generar el keystore de firma

La clave privada **no** se versiona ni se comparte: si se pierde, los usuarios
ya instalados no podrán actualizar y tendrán que desinstalar la app (perdiendo
sus datos locales). Guárdala en un gestor de contraseñas o en una copia de
seguridad cifrada.

```bash
keytool -genkey -v -keystore stronger-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias stronger
```

`-validity 10000` son ~27 años: una vez publicada la primera versión, la app
queda atada a esta clave para siempre, así que conviene que no caduque antes.

### 2. Cargar los secrets en GitHub

En *Settings → Secrets and variables → Actions*, crea cuatro secrets:

| Secret | Contenido |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | El `.jks` codificado en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Contraseña del keystore |
| `ANDROID_KEY_ALIAS` | `stronger` (el `-alias` de arriba) |
| `ANDROID_KEY_PASSWORD` | Contraseña de la clave |

Para el base64, en PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("stronger-release.jks")) |
  Set-Clipboard
```

### 3. Firmar en local (opcional)

Solo hace falta si quieres generar un APK distribuible desde tu máquina. Crea
`android/key.properties` — está en `.gitignore`, no lo subas:

```properties
storeFile=F:\\ruta\\a\\stronger-release.jks
storePassword=...
keyAlias=stronger
keyPassword=...
```

`storeFile` admite ruta absoluta o relativa a `android/app/`. Sin este fichero,
`flutter build apk --release` sigue funcionando pero firma con las claves de
debug y Gradle avisa de que ese APK no es distribuible.

## Publicar una versión

1. Sube la versión en [`pubspec.yaml`](../pubspec.yaml). El número tras `+` es
   el `versionCode` de Android y **debe crecer siempre**:

   ```yaml
   version: 2.1.0+3
   ```

2. Commitea y etiqueta con la misma versión que el `pubspec` (sin el `+`):

   ```bash
   git commit -am "version 2.1.0"
   git tag v2.1.0
   git push && git push --tags
   ```

3. El workflow comprueba que la etiqueta y el `pubspec` coinciden, pasa
   `analyze` y los tests, compila el APK firmado, verifica que no lleva la clave
   de debug y crea la release con `stronger-2.1.0.apk` adjunto y las notas
   generadas a partir de los commits.

Si algo falla, no se publica nada: borra la etiqueta (`git tag -d v2.1.0` y
`git push --delete origin v2.1.0`), corrige y vuelve a etiquetar.

## App Check y la distribución fuera de Play

**Play Integrity solo atesta apps que Google Play reconoce.** En un APK
instalado a mano la atestación devuelve `403 App attestation failed`, y como
`firebase_ai` pide el token de App Check sin capturar el error, la petición al
coach ni siquiera llegaba a enviarse.

Por eso [`main.dart`](../lib/main.dart) **no activa App Check en las release de
Android**: al no registrarse el servicio, `firebase_ai` no lo consulta y la
petición sale sin cabecera. En debug se sigue usando `AndroidDebugProvider`
(hay que registrar el token en la consola) y en web `ReCaptchaV3Provider`.

Para que el backend acepte esas peticiones sin token, Firebase AI Logic debe
quedarse **sin imponer** en *Firebase console → Security → App Check*,
desplegando la fila del producto y pulsando *Unenforce*. Cloud Firestore no
está impuesto y no hace falta tocarlo.

Es una renuncia consciente de protección antiabuso a cambio de poder distribuir
fuera de Play: quien extraiga la configuración del APK podría llamar a Gemini
contra la cuota del proyecto.

### Fecha límite: 2 de noviembre de 2026

Según la
[documentación de Firebase AI Logic](https://firebase.google.com/docs/ai-logic/app-check),
a partir de esa fecha App Check pasa a ser **obligatorio** para Firebase AI
Logic y no podrá desactivarse. Ese día un APK distribuido desde el repositorio
dejará de poder usar el coach tal y como está ahora.

Las salidas, por orden de esfuerzo:

1. **`AndroidReCaptchaProvider`** — el plugin `firebase_app_check` lo expone y,
   a diferencia de Play Integrity, reCAPTCHA no exige que Google Play reconozca
   la app. Requiere una clave de reCAPTCHA Enterprise en Google Cloud. Es la vía
   más prometedora y está pendiente de probar.
2. **Mover la llamada de IA a una Cloud Function** autenticada con el token de
   Firebase Auth del usuario, sacando `firebase_ai` del cliente.
3. **Publicar en Google Play**, aunque sea en una pista de testing interna, que
   es lo que se descartó al elegir esta forma de distribución.
