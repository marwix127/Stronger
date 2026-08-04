# Configuración de Firebase AI Logic

Stronger accede a Gemini mediante Firebase AI Logic. Su proxy conserva la
credencial de Gemini en la infraestructura de Firebase y valida las peticiones
de la aplicación con App Check. No hay que crear ni guardar una API key de
Gemini en el repositorio.

## Activación en Firebase Console

1. Abre el proyecto `stronger-f7c9c` en Firebase Console.
2. Entra en **AI Services > AI Logic** y selecciona **Get started**.
3. Elige **Gemini Developer API**, que admite el plan Spark.
4. Completa el asistente para habilitar las APIs necesarias.
5. En **AI Logic > Settings**, activa el modo que exige usuarios autenticados.
6. Revisa y ajusta los límites de peticiones por usuario.

La aplicación usa `gemini-3.5-flash`. Si el servicio no está activado, el chat
mostrará un mensaje de configuración en lugar de un error técnico.

## App Check

Firebase AI Logic debe estar protegido con App Check antes de compartir la
aplicación.

- Android producción: Play Integrity.
- Android desarrollo: proveedor debug y token registrado en Firebase Console.
- iOS/macOS producción: App Attest con fallback a DeviceCheck.
- iOS/macOS desarrollo: proveedor debug.
- Web: reCAPTCHA v3 y su clave pública mediante `RECAPTCHA_SITE_KEY`.

Ejemplo web:

```bash
flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=public_site_key
flutter build web --release --dart-define=RECAPTCHA_SITE_KEY=public_site_key
```

La clave de sitio de reCAPTCHA y la configuración habitual de Firebase son
públicas. Ninguna de ellas es una API key de Gemini.

## Flujo de datos

### Coach

1. La app comprueba que exista una sesión de Firebase Auth.
2. Lee un máximo de 50 entrenamientos y 30 medidas del usuario autenticado.
3. Normaliza y limita el contexto antes de enviarlo.
4. Firebase AI Logic valida App Check y autenticación y llama a Gemini.
5. La conversación se conserva localmente y separada por usuario.

### Fatiga muscular

1. El entrenamiento se guarda primero en Firestore.
2. En entrenamientos nuevos, la app solicita una respuesta JSON estructurada.
3. Solo se aceptan músculos conocidos y valores entre 0 y 100.
4. El resultado se combina en una transacción con la fatiga todavía activa.
5. La recuperación se calcula linealmente durante 72 horas.

El entrenamiento queda guardado aunque la estimación de IA falle o se agote la
cuota gratuita. Al ejecutarse desde el cliente, la estimación de fatiga es una
función de apoyo y no una fuente de datos con garantías de servidor.

## Límites del plan Spark

Gemini Developer API ofrece una cuota gratuita sujeta a límites. Cuando se
supera, las peticiones de IA fallan temporalmente sin impedir el resto de la
aplicación. Authentication, Firestore y Hosting mantienen sus propios límites
del plan Spark.
