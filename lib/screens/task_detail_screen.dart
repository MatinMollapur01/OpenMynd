import 'package:flutter/material.dart';
import 'package:openmynd/l10n/app_localizations.dart';
import '../models/task.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task? task;

  const TaskDetailScreen({super.key, this.task});

  @override
  TaskDetailScreenState createState() => TaskDetailScreenState();
}

class TaskDetailScreenState extends State<TaskDetailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  late String _category;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _category = widget.task?.category ?? 'default';
    _tagsController = TextEditingController(text: widget.task?.tags.join(', ') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? localizations.addTask : localizations.editTask),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: localizations.title,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: localizations.priority,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'low', child: Text(localizations.lowPriority)),
                  DropdownMenuItem(value: 'medium', child: Text(localizations.mediumPriority)),
                  DropdownMenuItem(value: 'high', child: Text(localizations.highPriority)),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _priority = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: localizations.category,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'default', child: Text(localizations.defaultCategory)),
                  DropdownMenuItem(value: 'work', child: Text(localizations.workCategory)),
                  DropdownMenuItem(value: 'personal', child: Text(localizations.personalCategory)),
                  DropdownMenuItem(value: 'health', child: Text(localizations.healthCategory)),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: localizations.tags,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTask,
                child: Text(widget.task == null ? localizations.addTask : localizations.updateTask),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        category: _category,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        isCompleted: widget.task?.isCompleted ?? false,
        completedDate: widget.task?.completedDate,
      );
      Navigator.of(context).pop(task);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
