import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Causa de un fallo de Firebase AI Logic, deducida del error devuelto.
enum AiFailure {
  /// Saturación o error temporal del servidor (5xx, `UNAVAILABLE`).
  overloaded,

  /// El modelo no existe, se ha retirado o no admite la petición.
  modelUnavailable,

  /// Cuota gratuita agotada para el modelo.
  quotaExceeded,

  /// App Check, autenticación o permisos rechazados.
  accessDenied,

  /// Firebase AI Logic no está activado en el proyecto.
  notEnabled,

  /// Cualquier otro error, incluidos los de red.
  unknown;

  /// Fallos que pueden resolverse probando con otro modelo.
  bool get allowsFallback =>
      this == overloaded || this == modelUnavailable || this == quotaExceeded;
}

AiFailure classifyAiError(Object error) {
  if (error is ServiceApiNotEnabled) return AiFailure.notEnabled;
  if (error is QuotaExceeded) return AiFailure.quotaExceeded;
  if (error is InvalidApiKey) return AiFailure.accessDenied;
  if (error is! FirebaseAIException) return AiFailure.unknown;

  final message = error.message.toLowerCase();
  if (_containsAny(message, const [
    'app check',
    'appcheck',
    'permission_denied',
    'permission denied',
    'unauthenticated',
    'unauthorized',
  ])) {
    return AiFailure.accessDenied;
  }
  if (_containsAny(message, const [
    'not found',
    'not_found',
    'is not supported',
    'no longer available',
    'deprecated',
  ])) {
    return AiFailure.modelUnavailable;
  }
  if (_containsAny(message, const [
    'server error',
    'overloaded',
    'unavailable',
    'resource_exhausted',
    'resource has been exhausted',
    'deadline_exceeded',
    'internal',
    'try again',
  ])) {
    return AiFailure.overloaded;
  }
  return AiFailure.unknown;
}

bool _containsAny(String text, List<String> patterns) =>
    patterns.any(text.contains);

/// Ejecuta una petición de IA con reintentos y modelos de respaldo.
///
/// Prueba los [models] en orden. Si un modelo está saturado, reintenta con
/// las esperas de [retryDelays] antes de pasar al siguiente. Si el modelo se
/// ha retirado o ha agotado su cuota, pasa directamente al siguiente. El resto
/// de errores, como los de App Check, se relanzan sin más intentos.
class AiModelRunner {
  final List<Duration> retryDelays;
  final Future<void> Function(Duration) _wait;

  AiModelRunner({
    this.retryDelays = const [Duration(seconds: 1), Duration(seconds: 2)],
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? Future<void>.delayed;

  Future<T> run<T>(
    List<String> models,
    Future<T> Function(String model) request,
  ) async {
    assert(models.isNotEmpty);
    late Object lastError;
    late StackTrace lastStackTrace;

    for (final model in models) {
      for (var attempt = 0; ; attempt++) {
        try {
          return await request(model);
        } catch (error, stackTrace) {
          final failure = classifyAiError(error);
          debugPrint('AI request with $model failed (${failure.name}): $error');
          lastError = error;
          lastStackTrace = stackTrace;

          if (failure == AiFailure.overloaded && attempt < retryDelays.length) {
            await _wait(retryDelays[attempt]);
            continue;
          }
          if (failure.allowsFallback) break;
          Error.throwWithStackTrace(error, stackTrace);
        }
      }
    }
    Error.throwWithStackTrace(lastError, lastStackTrace);
  }
}
