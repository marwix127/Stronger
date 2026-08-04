import 'package:stronger/models/training.dart';
import 'package:stronger/infrastructure/services/firebase/training_service.dart';
import 'package:stronger/infrastructure/services/training_draft_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TrainingHistoryPage extends StatefulWidget {
  final TrainingService? trainingService;
  final TrainingDraftStore? draftStore;

  const TrainingHistoryPage({super.key, this.trainingService, this.draftStore});

  @override
  State<TrainingHistoryPage> createState() => _TrainingHistoryPageState();
}

class _TrainingHistoryPageState extends State<TrainingHistoryPage> {
  late Future<List<Training>> _trainingsFuture;
  late final TrainingService _trainingService;
  late final TrainingDraftStore _draftStore;
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _trainingService = widget.trainingService ?? TrainingService();
    _draftStore = widget.draftStore ?? SharedPreferencesTrainingDraftStore();
    _trainingsFuture = _trainingService.getTrainings();
    _checkDraft();
  }

  Future<void> _checkDraft() async {
    final hasDraft = await _draftStore.exists();
    if (mounted) {
      setState(() {
        _hasDraft = hasDraft;
      });
    }
  }

  void _navigateToNewTraining() async {
    final result = await context.push('/training');
    _checkDraft(); // Re-comprobar después de volver
    if (result != null) {
      setState(() {
        _trainingsFuture = _trainingService.getTrainings();
      });
    }
  }

  void _navigateToDraft() async {
    final result = await context.push('/training?loadDraft=true');
    _checkDraft(); // Re-comprobar después de volver
    if (result != null) {
      setState(() {
        _trainingsFuture = _trainingService.getTrainings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasDraft) ...[
            FloatingActionButton(
              heroTag: 'draft_fab',
              onPressed: _navigateToDraft,
              tooltip: "Continuar borrador",
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.edit_note),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'new_training_fab',
            onPressed: _navigateToNewTraining,
            tooltip: "Nuevo entrenamiento",
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Training>>(
        future: _trainingsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se han podido cargar los entrenamientos.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _trainingsFuture = _trainingService.getTrainings();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trainings = snapshot.data ?? [];
          if (trainings.isEmpty) {
            return const Center(
              child: Text("No hay entrenamientos registrados."),
            );
          }

          return ListView.builder(
            itemCount: trainings.length,
            itemBuilder: (context, index) {
              final training = trainings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(training.name),
                  subtitle: Text(
                    "Fecha: ${DateFormat('dd/MM/yyyy').format(training.date.toLocal())}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await context.push(
                      '/training',
                      extra: training,
                    );
                    if (result == true) {
                      setState(() {
                        _trainingsFuture = _trainingService.getTrainings();
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
