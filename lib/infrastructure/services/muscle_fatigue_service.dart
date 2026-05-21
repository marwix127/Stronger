import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:stronger/models/training.dart';

class MuscleFatigueService {
  static const _recoveryHours = 72.0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call this after saving a training. Fire-and-forget — does not block UI.
  Future<void> analyzeAndUpdate(Training training, String uid) async {
    try {
      final scores = await _analyzeWithGemini(training);
      debugPrint('[MuscleFatigue] Gemini scores: $scores');
      if (scores.isEmpty) return;
      await _updateFirestore(uid, scores);
      debugPrint('[MuscleFatigue] Firestore updated OK');
    } catch (e) {
      debugPrint('[MuscleFatigue] ERROR: $e');
    }
  }

  // Returns effective (decayed) scores for every muscle with data.
  Future<Map<String, double>> loadCurrentScores(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('muscle_data')
          .doc('scores')
          .get();

      if (!doc.exists) return {};

      final result = <String, double>{};
      for (final entry in doc.data()!.entries) {
        final muscle = entry.value as Map<String, dynamic>;
        final score = (muscle['score'] as num).toDouble();
        final updatedAt = (muscle['updatedAt'] as Timestamp).toDate();
        final effective = _applyDecay(score, updatedAt);
        if (effective >= 1) result[entry.key] = effective;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  double _applyDecay(double score, DateTime updatedAt) {
    final hours = DateTime.now().difference(updatedAt).inMinutes / 60.0;
    final factor = (1 - hours / _recoveryHours).clamp(0.0, 1.0);
    return score * factor;
  }

  Future<Map<String, double>> _analyzeWithGemini(Training training) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return {};

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    final prompt =
        '''
Analiza este entrenamiento de fitness y devuelve ÚNICAMENTE un JSON válido con el nivel de fatiga muscular (0-100) para cada grupo muscular afectado.

Grupos musculares disponibles (usa exactamente estas claves):
chest, frontShoulders, biceps, forearms, abs, quads, calves, traps, lats, rearShoulders, triceps, lowerBack, glutes, hamstrings

Criterios:
- Considera el volumen total (series × repeticiones × peso)
- Músculo primario recibe más fatiga que músculo secundario/estabilizador
- Más repeticiones con menos peso = menos fatiga por serie
- Solo incluye los músculos realmente trabajados

Devuelve SOLO el JSON sin markdown ni texto adicional.

Entrenamiento:
${_formatTraining(training)}

Ejemplo de respuesta: {"chest": 80, "frontShoulders": 45, "triceps": 60}
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return _parseScores(response.text ?? '');
  }

  Map<String, double> _parseScores(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1) return {};

    try {
      final decoded =
          jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  String _formatTraining(Training training) {
    final buf = StringBuffer('Entrenamiento: ${training.name}\n');
    for (final ex in training.exercises) {
      buf.writeln('- ${ex.name} (${ex.category}):');
      for (final s in ex.series) {
        buf.writeln('  ${s.repetitions} reps × ${s.weight}kg');
      }
    }
    return buf.toString();
  }

  Future<void> _updateFirestore(
    String uid,
    Map<String, double> newScores,
  ) async {
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('muscle_data')
        .doc('scores');

    final existing = await docRef.get();
    final now = Timestamp.now();
    final updates = <String, dynamic>{};

    for (final entry in newScores.entries) {
      double combined = entry.value;

      if (existing.exists) {
        final prev = (existing.data()!)[entry.key] as Map<String, dynamic>?;
        if (prev != null) {
          final prevScore = (prev['score'] as num).toDouble();
          final prevAt = (prev['updatedAt'] as Timestamp).toDate();
          combined = (_applyDecay(prevScore, prevAt) + entry.value).clamp(
            0.0,
            100.0,
          );
        }
      }

      updates[entry.key] = {'score': combined, 'updatedAt': now};
    }

    await docRef.set(updates, SetOptions(merge: true));
  }
}
