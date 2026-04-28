import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExercisesByCategories extends StatefulWidget {
  final String categoria;
  const ExercisesByCategories({required this.categoria, super.key});

  @override
  State<ExercisesByCategories> createState() => _ExercisesByCategoriesState();
}

class _ExercisesByCategoriesState extends State<ExercisesByCategories> {
  late final Future<List<Map<String, dynamic>>> _ejerciciosFuture;

  @override
  void initState() {
    super.initState();
    _ejerciciosFuture = EjercicioService().obtenerPorCategoria(widget.categoria);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoria),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-exercise'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ejerciciosFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ejercicios = snapshot.data!;
          return ListView.builder(
            itemCount: ejercicios.length,
            itemBuilder: (context, index) {
              final ejercicio = ejercicios[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(ejercicio['nombre']),
                subtitle: Text(
                  ejercicio['descripcion'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () => Navigator.pop(context, ejercicio),
              );
            },
          );
        },
      ),
    );
  }
}
