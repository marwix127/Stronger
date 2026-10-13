import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Modelos de Gemini que usa la aplicación, configurables con Remote Config.
///
/// Cada parámetro es una lista de modelos separados por comas, en orden de
/// preferencia. Los modelos por defecto se añaden siempre al final como último
/// respaldo, así que un valor erróneo en la consola no deja la IA sin servicio.
class AiModelConfig {
  static const coachModelsKey = 'coach_models';
  static const muscleFatigueModelsKey = 'muscle_fatigue_models';

  static const defaultCoachModels = [
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
  ];

  /// La estimación de fatiga es una tarea sencilla: empieza por Flash-Lite,
  /// que tiene más cuota gratuita, y deja Flash como respaldo.
  static const defaultMuscleFatigueModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.6-flash',
  ];

  static final instance = AiModelConfig._();

  AiModelConfig._();

  String Function(String key)? _readValue;

  List<String> get coachModels =>
      resolveAiModels(_readValue?.call(coachModelsKey), defaultCoachModels);

  List<String> get muscleFatigueModels => resolveAiModels(
    _readValue?.call(muscleFatigueModelsKey),
    defaultMuscleFatigueModels,
  );

  /// Activa los valores guardados y descarga los nuevos en segundo plano.
  ///
  /// Si Remote Config no está disponible en la plataforma o falla la descarga,
  /// se siguen usando los últimos valores activados o los modelos por defecto.
  Future<void> initialize() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults({
        coachModelsKey: defaultCoachModels.join(','),
        muscleFatigueModelsKey: defaultMuscleFatigueModels.join(','),
      });
      _readValue = remoteConfig.getString;
      await remoteConfig.fetchAndActivate();
      debugPrint(
        'AI models: coach=$coachModels, muscle fatigue=$muscleFatigueModels',
      );
    } catch (error, stackTrace) {
      debugPrint('Remote Config unavailable: $error\n$stackTrace');
    }
  }
}

final _modelNamePattern = RegExp(r'^[a-z0-9][a-z0-9.\-]*$');

/// Convierte el valor de Remote Config en una lista ordenada de modelos.
///
/// Descarta nombres no válidos y duplicados, y añade al final los [defaults]
/// que no aparezcan en el valor configurado.
@visibleForTesting
List<String> resolveAiModels(String? configured, List<String> defaults) {
  final models = <String>{};
  for (final name in (configured ?? '').split(',')) {
    final model = name.trim().toLowerCase();
    if (_modelNamePattern.hasMatch(model)) models.add(model);
  }
  models.addAll(defaults);
  return models.toList(growable: false);
}
