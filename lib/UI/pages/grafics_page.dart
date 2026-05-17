import 'package:stronger/infrastructure/services/firebase/training_service.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/training.dart';
import 'package:flutter/material.dart';
import 'package:stronger/UI/widgets/volume_chart.dart';
import 'package:stronger/UI/widgets/average_weight.dart';

List<Map<String, dynamic>> calculateVolumePerExercise(
  List<Training> trainings,
  String exerciseName,
) {
  return trainings
      .map((training) {
        final exercise = training.exercises.firstWhere(
          (e) => e.name.toLowerCase() == exerciseName.toLowerCase(),
          orElse: () =>
              SelectedExercise(id: '', name: '', category: '', series: []),
        );

        final volume = exercise.series.fold<double>(
          0,
          (total, serie) => total + (serie.weight * serie.repetitions),
        );

        return {'date': training.date, 'volume': volume};
      })
      .where((e) => (e['volume'] as num) > 0)
      .toList();
}

List<Map<String, dynamic>> calculateAverageWeightPerExercise(
  List<Training> trainings,
  String exerciseName,
) {
  return trainings
      .map((training) {
        final exercise = training.exercises.firstWhere(
          (e) => e.name.toLowerCase() == exerciseName.toLowerCase(),
          orElse: () =>
              SelectedExercise(id: '', name: '', category: '', series: []),
        );

        if (exercise.series.isEmpty) {
          return {'date': training.date, 'average_weight': 0.0};
        }

        final totalWeight = exercise.series.fold<double>(
          0,
          (total, serie) => total + serie.weight,
        );
        final average = totalWeight / exercise.series.length;

        return {'date': training.date, 'average_weight': average};
      })
      .where((e) => (e['average_weight'] as num) > 0)
      .toList();
}

class GraficsPage extends StatefulWidget {
  const GraficsPage({super.key});

  @override
  State<GraficsPage> createState() => _GraficsPageState();
}

class _GraficsPageState extends State<GraficsPage> {
  final _trainingService = TrainingService();
  List<Training> _trainings = [];
  String? _selectedExercise;
  String _chartType = 'Volume';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    final loaded = await _trainingService.getTrainings();
    setState(() {
      _trainings = loaded;
      _loading = false;
    });
  }

  List<String> _getAllExercises() {
    final all = _trainings
        .expand((t) => t.exercises)
        .map((e) => e.name)
        .toSet()
        .toList();
    all.sort();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chartData = _selectedExercise == null
        ? <Map<String, dynamic>>[]
        : _chartType == 'Volume'
        ? calculateVolumePerExercise(_trainings, _selectedExercise!)
        : calculateAverageWeightPerExercise(_trainings, _selectedExercise!);

    return Scaffold(
      appBar: AppBar(title: const Text("Volumen de Entrenamiento")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: const Text("Selecciona un ejercicio"),
              value: _selectedExercise,
              isExpanded: true,
              items: _getAllExercises()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedExercise = value);
              },
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Volume', label: Text('Volumen')),
                ButtonSegment(
                    value: 'Average Weight', label: Text('Peso Medio')),
              ],
              selected: {_chartType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _chartType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 20),
            if (chartData.isEmpty)
              const Text("No hay datos para este ejercicio")
            else
              Expanded(
                child: _chartType == 'Volume'
                    ? VolumenChart(data: chartData)
                    : AverageWeightChart(data: chartData),
              ),
          ],
        ),
      ),
    );
  }
}
