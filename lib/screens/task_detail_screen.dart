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
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _category = widget.task?.category ?? 'default';
    _dueDate = widget.task?.dueDate;
    _dueTime = widget.task?.dueDate != null ? TimeOfDay.fromDateTime(widget.task!.dueDate!) : null;
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
              ListTile(
                title: Text(
                  _dueDate == null
                      ? localizations.dueDate
                      : '${localizations.dueDate}: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text(
                  _dueTime == null
                      ? localizations.dueTime
                      : '${localizations.dueTime}: ${_dueTime!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _dueDate) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _dueTime) {
      setState(() {
        _dueTime = pickedTime;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final DateTime? combinedDateTime = _dueDate != null && _dueTime != null
          ? DateTime(
              _dueDate!.year,
              _dueDate!.month,
              _dueDate!.day,
              _dueTime!.hour,
              _dueTime!.minute,
            )
          : null;

      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: combinedDateTime,
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
