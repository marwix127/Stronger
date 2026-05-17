import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExerciseManagementByCategory extends StatefulWidget {
  final String category;
  const ExerciseManagementByCategory({required this.category, super.key});

  @override
  State<ExerciseManagementByCategory> createState() =>
      _ExerciseManagementByCategoryState();
}

class _ExerciseManagementByCategoryState
    extends State<ExerciseManagementByCategory> {
  final _exerciseService = ExerciseService();
  late Future<List<Map<String, dynamic>>> _futureExercises;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _futureExercises = _exerciseService.getByCategory(widget.category);
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: const Text(
          '¿Seguro que quieres eliminar este ejercicio? Se perderán todos los datos relacionados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _exerciseService.deleteExercise(exercise['id']);
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/add-exercise');
              _refreshList();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureExercises,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercises = snapshot.data!;

          if (exercises.isEmpty) {
            return const Center(
              child: Text('No hay ejercicios en esta categoría'),
            );
          }

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(exercise['nombre']),
                subtitle: Text(
                  exercise['descripcion'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: () => _confirmDelete(exercise),
                ),
                onTap: () async {
                  await context.push('/add-exercise', extra: exercise);
                  _refreshList();
                },
              );
            },
          );
        },
      ),
    );
  }
}
