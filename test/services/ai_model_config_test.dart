import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/ai_model_config.dart';

void main() {
  const defaults = ['gemini-3.6-flash', 'gemini-3.5-flash-lite'];

  group('resolveAiModels', () {
    test('uses the defaults when nothing is configured', () {
      expect(resolveAiModels(null, defaults), defaults);
      expect(resolveAiModels('', defaults), defaults);
    });

    test('puts configured models first and keeps defaults as fallback', () {
      expect(
        resolveAiModels(' gemini-3.8-flash , gemini-3.6-flash', defaults),
        ['gemini-3.8-flash', 'gemini-3.6-flash', 'gemini-3.5-flash-lite'],
      );
    });

    test('discards invalid names and duplicates', () {
      expect(
        resolveAiModels(
          'Gemini-3.8-Flash,gemini-3.8-flash,../hack, ,models/x',
          defaults,
        ),
        ['gemini-3.8-flash', ...defaults],
      );
    });
  });

  test('falls back to defaults before Remote Config is initialized', () {
    expect(
      AiModelConfig.instance.coachModels,
      AiModelConfig.defaultCoachModels,
    );
    expect(
      AiModelConfig.instance.muscleFatigueModels,
      AiModelConfig.defaultMuscleFatigueModels,
    );
  });
}
