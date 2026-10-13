import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/ai_model_runner.dart';

void main() {
  group('classifyAiError', () {
    test('recognizes typed Firebase AI exceptions', () {
      expect(classifyAiError(QuotaExceeded('quota')), AiFailure.quotaExceeded);
      expect(
        classifyAiError(ServiceApiNotEnabled('projects/demo')),
        AiFailure.notEnabled,
      );
      expect(classifyAiError(InvalidApiKey('bad key')), AiFailure.accessDenied);
    });

    test('recognizes server overload', () {
      expect(
        classifyAiError(
          FirebaseAIException(
            'Server Error [503]: {"error": {"status": "UNAVAILABLE"}}',
          ),
        ),
        AiFailure.overloaded,
      );
      expect(
        classifyAiError(ServerException('The model is overloaded.')),
        AiFailure.overloaded,
      );
    });

    test('recognizes retired models', () {
      expect(
        classifyAiError(
          ServerException(
            'models/gemini-old is not found for API version v1beta.',
          ),
        ),
        AiFailure.modelUnavailable,
      );
    });

    test('recognizes App Check and authentication failures', () {
      expect(
        classifyAiError(
          ServerException('Firebase App Check token is invalid.'),
        ),
        AiFailure.accessDenied,
      );
      expect(
        classifyAiError(ServerException('Request had UNAUTHENTICATED status')),
        AiFailure.accessDenied,
      );
    });

    test('treats other errors as unknown', () {
      expect(classifyAiError(Exception('network')), AiFailure.unknown);
      expect(
        classifyAiError(FirebaseAIException('Invalid JSON payload')),
        AiFailure.unknown,
      );
    });
  });

  group('AiModelRunner', () {
    late List<Duration> waits;
    late List<String> calls;

    Future<T> run<T>(Future<T> Function(String model) request) => AiModelRunner(
      wait: (duration) async => waits.add(duration),
    ).run(const ['primary', 'fallback'], request);

    setUp(() {
      waits = [];
      calls = [];
    });

    test('returns the first successful response', () async {
      final result = await run((model) async {
        calls.add(model);
        return 'ok';
      });

      expect(result, 'ok');
      expect(calls, ['primary']);
      expect(waits, isEmpty);
    });

    test('retries an overloaded model with backoff', () async {
      final result = await run((model) async {
        calls.add(model);
        if (calls.length < 3) throw ServerException('The model is overloaded.');
        return 'ok';
      });

      expect(result, 'ok');
      expect(calls, ['primary', 'primary', 'primary']);
      expect(waits, const [Duration(seconds: 1), Duration(seconds: 2)]);
    });

    test('falls back after exhausting retries', () async {
      final result = await run((model) async {
        calls.add(model);
        if (model == 'primary') {
          throw FirebaseAIException('Server Error [503]: UNAVAILABLE');
        }
        return 'fallback ok';
      });

      expect(result, 'fallback ok');
      expect(calls, ['primary', 'primary', 'primary', 'fallback']);
    });

    test('falls back immediately when the model is retired', () async {
      final result = await run((model) async {
        calls.add(model);
        if (model == 'primary') throw ServerException('model is not found');
        return 'fallback ok';
      });

      expect(result, 'fallback ok');
      expect(calls, ['primary', 'fallback']);
      expect(waits, isEmpty);
    });

    test('falls back immediately when the quota is exhausted', () async {
      final result = await run((model) async {
        calls.add(model);
        if (model == 'primary') throw QuotaExceeded('quota');
        return 'fallback ok';
      });

      expect(result, 'fallback ok');
      expect(calls, ['primary', 'fallback']);
    });

    test('does not retry access errors', () async {
      await expectLater(
        run<String>((model) async {
          calls.add(model);
          throw ServerException('App Check token is invalid');
        }),
        throwsA(isA<ServerException>()),
      );
      expect(calls, ['primary']);
    });

    test('rethrows the last error when every model fails', () async {
      await expectLater(
        run<String>((model) async {
          calls.add(model);
          throw QuotaExceeded('quota for $model');
        }),
        throwsA(
          isA<QuotaExceeded>().having(
            (error) => error.message,
            'message',
            'quota for fallback',
          ),
        ),
      );
      expect(calls, ['primary', 'fallback']);
    });
  });
}
