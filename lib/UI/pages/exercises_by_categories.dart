import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExercisesByCategories extends StatefulWidget {
  final String category;
  const ExercisesByCategories({required this.category, super.key});

  @override
  State<ExercisesByCategories> createState() => _ExercisesByCategoriesState();
}

class _ExercisesByCategoriesState extends State<ExercisesByCategories> {
  late final Future<List<Map<String, dynamic>>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = ExerciseService().getByCategory(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-exercise'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercises = snapshot.data!;
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
                onTap: () => Navigator.pop(context, exercise),
              );
            },
          );
        },
      ),
    );
  }
}
