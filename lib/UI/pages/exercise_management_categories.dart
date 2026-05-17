import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'exercise_management_by_category.dart';

class ExerciseManagementCategories extends StatefulWidget {
  const ExerciseManagementCategories({super.key});

  @override
  State<ExerciseManagementCategories> createState() =>
      _ExerciseManagementCategoriesState();
}

class _ExerciseManagementCategoriesState
    extends State<ExerciseManagementCategories> {
  final _exerciseService = ExerciseService();
  late Future<List<String>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _futureCategories = _exerciseService.getUniqueCategories();
    });
  }

  Future<void> _editCategory(String category) async {
    final controller = TextEditingController(text: category);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar categoría'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != category) {
      await _exerciseService.renameCategory(category, newName);
      _refreshList();
    }
  }

  Future<void> _deleteCategory(String category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Seguro que quieres eliminar la categoría "$category"?\n\n'
          'Se eliminarán TODOS los ejercicios de esta categoría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _exerciseService.deleteCategory(category);
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Ejercicios'),
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
      body: FutureBuilder<List<String>>(
        future: _futureCategories,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;

          if (categories.isEmpty) {
            return const Center(child: Text('No hay categorías'));
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editCategory(category),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: colorScheme.error),
                      onPressed: () => _deleteCategory(category),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExerciseManagementByCategory(category: category),
                    ),
                  );
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
