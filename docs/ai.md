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

## Modelos, reintentos y respaldo

Los modelos por defecto están en
`lib/infrastructure/services/ai_model_config.dart`:

| Uso | Parámetro de Remote Config | Modelo principal | Respaldo |
|---|---|---|---|
| Coach | `coach_models` | `gemini-3.6-flash` | `gemini-3.5-flash-lite` |
| Fatiga muscular | `muscle_fatigue_models` | `gemini-3.5-flash-lite` | `gemini-3.6-flash` |

### Cambiar de modelo sin publicar una versión

1. En Firebase Console, abre **Run > Remote Config**.
2. Crea el parámetro `coach_models` o `muscle_fatigue_models` de tipo
   **String**.
3. Escribe los modelos en orden de preferencia, separados por comas. Por
   ejemplo: `gemini-3.8-flash,gemini-3.6-flash`.
4. Publica los cambios.

La aplicación descarga la configuración al arrancar, como mucho una vez por
hora, y la aplica en cuanto llega. Los modelos por defecto se añaden siempre al
final de la lista y los nombres no válidos se descartan, así que un error en la
consola no deja la IA sin servicio. Si Remote Config no responde, se usan los
últimos valores descargados o los modelos por defecto. Con los emuladores de
Firebase no se consulta Remote Config.

`AiModelRunner` (`lib/infrastructure/services/ai_model_runner.dart`) clasifica
cada error de Firebase AI Logic y actúa según la causa:

- **Saturación** (5xx, `UNAVAILABLE`): reintenta tras 1 s y 2 s y, si sigue
  fallando, pasa al modelo de respaldo.
- **Modelo retirado** o **cuota agotada**: pasa directamente al respaldo.
- **App Check, autenticación** o **servicio sin activar**: falla sin reintentos.

El chat muestra un mensaje distinto para cada causa. El error técnico completo
se registra con `debugPrint` (`AI request with <modelo> failed (<causa>)`) y se
puede consultar en la consola de depuración o con `adb logcat`.

Antes de cambiar un modelo, consulta la
[lista de modelos retirados](https://ai.google.dev/gemini-api/docs/deprecations).

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
