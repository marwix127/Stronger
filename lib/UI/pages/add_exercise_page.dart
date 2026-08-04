import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';

class AddExercisePage extends StatefulWidget {
  final Map<String, dynamic>? exercise;
  final ExerciseService? exerciseService;

  const AddExercisePage({super.key, this.exercise, this.exerciseService});

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final ExerciseService _exerciseService;
  List<String> _categories = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _exerciseService = widget.exerciseService ?? ExerciseService();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!['nombre'] ?? '';
      _descriptionController.text = widget.exercise!['descripcion'] ?? '';
      _categoryController.text = widget.exercise!['categoria'] ?? '';
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _exerciseService.getUniqueCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('No se han podido cargar las categorías');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? 'Sin descripción'
        : _descriptionController.text.trim();

    if (name.isEmpty || category.isEmpty) {
      _showError('Completa los campos obligatorios');
      return;
    }

    setState(() => _saving = true);
    try {
      final data = {
        'nombre': name,
        'descripcion': description,
        'categoria': category,
      };
      if (widget.exercise case final exercise?) {
        await _exerciseService.updateExercise(exercise['id'], data);
      } else {
        await _exerciseService.addCustomExercise(data);
      }
      if (mounted) context.pop(true);
    } catch (_) {
      _showError('No se ha podido guardar el ejercicio');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exercise != null ? 'Editar ejercicio' : 'Añadir ejercicio',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del ejercicio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Añadir descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    initialValue: TextEditingValue(
                      text: _categoryController.text,
                    ),
                    optionsBuilder: (value) {
                      if (value.text.isEmpty) return _categories;
                      return _categories.where(
                        (option) => option.toLowerCase().startsWith(
                          value.text.toLowerCase(),
                        ),
                      );
                    },
                    onSelected: (selection) {
                      _categoryController.text = selection;
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Categoría (elige o crea una)',
                              border: OutlineInputBorder(),
                            ),
                            onEditingComplete: onEditingComplete,
                            onChanged: (value) {
                              _categoryController.text = value;
                            },
                          );
                        },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      widget.exercise != null
                          ? 'Actualizar ejercicio'
                          : 'Guardar ejercicio',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
