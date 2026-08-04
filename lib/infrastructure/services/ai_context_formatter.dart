import 'package:cloud_firestore/cloud_firestore.dart';

class AiContextFormatter {
  static const _maxContextLength = 14000;

  static String formatTrainingHistory(
    Iterable<Map<String, dynamic>> trainings,
  ) {
    final buffer = StringBuffer();

    for (final training in trainings) {
      final name = _text(training['name'] ?? training['nombre'], 'Sin nombre');
      buffer.writeln('- ${_date(training['date'])}: $name');

      final exercises = training['exercises'];
      if (exercises is! List) continue;

      for (final rawExercise in exercises) {
        if (rawExercise is! Map) continue;
        final exercise = Map<String, dynamic>.from(rawExercise);
        final exerciseName = _text(
          exercise['name'] ?? exercise['nombre'],
          'Ejercicio',
        );
        final formattedSeries = <String>[];
        final series = exercise['series'];
        if (series is List) {
          for (final rawSeries in series) {
            if (rawSeries is! Map) continue;
            final repetitions = _number(rawSeries['repetitions']) ?? 0;
            final weight = _number(rawSeries['weight']) ?? 0;
            formattedSeries.add(
              '${_compact(repetitions)}x${_compact(weight)}kg',
            );
          }
        }
        buffer.writeln('  * $exerciseName: ${formattedSeries.join(', ')}');
      }

      if (buffer.length >= _maxContextLength) break;
    }

    return _bounded(
      buffer.toString().trim(),
      fallback: 'No hay entrenamientos registrados.',
    );
  }

  static String formatBodyMeasurements(
    Iterable<Map<String, dynamic>> measurements,
  ) {
    final buffer = StringBuffer();

    for (final measurement in measurements) {
      final parts = <String>[];
      _addNumber(parts, 'Peso', measurement['weight'], 'kg');
      _addNumber(parts, 'Altura', measurement['height'], 'cm');
      _addNumber(
        parts,
        'Grasa',
        measurement['fat_percentage'] ?? measurement['currentBodyFat'],
        '%',
      );
      _addNumber(
        parts,
        'Músculo',
        measurement['muscle_mass'] ?? measurement['currentMuscle'],
        'kg',
      );
      if (parts.isNotEmpty) {
        buffer.writeln('- ${_date(measurement['date'])}: ${parts.join(', ')}');
      }
    }

    return _bounded(
      buffer.toString().trim(),
      fallback: 'No hay mediciones corporales registradas.',
    );
  }

  static List<Map<String, String>> sanitizeHistory(Object? history) {
    if (history is! List) return const [];

    final result = <Map<String, String>>[];
    for (final rawTurn in history) {
      if (rawTurn is! Map) continue;
      final role = rawTurn['role'];
      final text = rawTurn['text'];
      if ((role != 'user' && role != 'assistant') || text is! String) continue;
      final cleanText = text.trim();
      if (cleanText.isEmpty) continue;
      result.add({'role': role as String, 'text': cleanText});
    }

    final recent = result.length > 12
        ? result.sublist(result.length - 12)
        : result;
    final alternating = <Map<String, String>>[];
    var expectedRole = 'user';
    for (final turn in recent) {
      if (turn['role'] != expectedRole) continue;
      alternating.add(turn);
      expectedRole = expectedRole == 'user' ? 'assistant' : 'user';
    }
    return alternating;
  }

  static String _bounded(String value, {required String fallback}) {
    if (value.isEmpty) return fallback;
    if (value.length <= _maxContextLength) return value;
    return '${value.substring(0, _maxContextLength)}\n[contexto truncado]';
  }

  static String _date(Object? value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value != null) {
      date = DateTime.tryParse(value.toString());
    }
    return date == null
        ? 'Fecha desconocida'
        : '${date.day}/${date.month}/${date.year}';
  }

  static String _text(Object? value, String fallback) {
    if (value is! String || value.trim().isEmpty) return fallback;
    return value.trim().replaceAll(RegExp(r'[\r\n]+'), ' ');
  }

  static num? _number(Object? value) {
    if (value is num && value.isFinite) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  static String _compact(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  static void _addNumber(
    List<String> parts,
    String label,
    Object? value,
    String unit,
  ) {
    final number = _number(value);
    if (number != null) parts.add('$label: ${_compact(number)} $unit');
  }
}
