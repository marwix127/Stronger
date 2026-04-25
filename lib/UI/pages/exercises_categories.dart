import 'package:business_ia/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'exercises_by_categories.dart';

class ExercisesCategories extends StatefulWidget {
  const ExercisesCategories({super.key});

  @override
  State<ExercisesCategories> createState() => _ExercisesCategoriesState();
}

class _ExercisesCategoriesState extends State<ExercisesCategories> {
  final _ejercicioService = EjercicioService();
  late final Future<List<String>> _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = _ejercicioService.obtenerCategoriasUnicas();
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
        future: _categoriasFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categorias = snapshot.data!;
          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              return ListTile(
                title: Text(categoria),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final nav = Navigator.of(context);
                  final ejercicio = await nav.push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ExercisesByCategories(categoria: categoria),
                    ),
                  );
                  if (!mounted) return;
                  if (ejercicio != null) {
                    nav.pop(ejercicio);
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
