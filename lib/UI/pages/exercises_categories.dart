import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'exercises_by_categories.dart';

class ExercisesCategories extends StatefulWidget {
  final ExerciseService? exerciseService;

  const ExercisesCategories({super.key, this.exerciseService});

  @override
  State<ExercisesCategories> createState() => _ExercisesCategoriesState();
}

class _ExercisesCategoriesState extends State<ExercisesCategories> {
  late final ExerciseService _exerciseService;
  late final Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _exerciseService = widget.exerciseService ?? ExerciseService();
    _categoriesFuture = _exerciseService.getUniqueCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos musculares'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-exercise'),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se han podido cargar las categorías'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final nav = Navigator.of(context);
                  final exercise = await nav.push(
                    MaterialPageRoute(
                      builder: (_) => ExercisesByCategories(
                        category: category,
                        exerciseService: _exerciseService,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  if (exercise != null) {
                    nav.pop(exercise);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
