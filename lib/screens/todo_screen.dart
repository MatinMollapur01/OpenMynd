import 'package:flutter/material.dart';
import 'package:openmynd/l10n/app_localizations.dart';
import 'package:openmynd/models/habit.dart';
import 'package:openmynd/models/task.dart';
import 'task_detail_screen.dart';
import 'completed_tasks_screen.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import 'package:logger/logger.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  TodoScreenState createState() => TodoScreenState();
}

class TodoScreenState extends State<TodoScreen> {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final NotificationService _notificationService = NotificationService();
  final DatabaseService _databaseService = DatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _databaseService.readAllTasks();
      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
      });
      _logger.i("Loaded ${tasks.length} tasks");
    } catch (e) {
      _logger.e("Error loading tasks: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).noTasks)),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _tasks.where((task) {
        return task.title.toLowerCase().contains(query) ||
            (task.description?.toLowerCase().contains(query) ?? false) ||
            task.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.todo),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompletedTasksScreen(
                    onTaskRestored: _loadTasks,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Checkbox(
                    value: _filteredTasks[index].isCompleted,
                    onChanged: (bool? value) {
                      setState(() {
                        _filteredTasks[index].isCompleted = value!;
                      });
                      _completeTask(_filteredTasks[index]);
                    },
                  ),
                  title: Text(_filteredTasks[index].title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getLocalizedCategory(_filteredTasks[index].category)),
                      Wrap(
                        spacing: 4,
                        children: _filteredTasks[index].tags.map((tag) => Chip(label: Text(tag))).toList(),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editTask(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTask(index),
                      ),
                    ],
                  ),
                  onTap: () => _viewTaskDetails(index),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: localizations.addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getLocalizedCategory(String category) {
    final localizations = AppLocalizations.of(context);
    switch (category) {
      case 'default':
        return localizations.defaultCategory;
      case 'work':
        return localizations.workCategory;
      case 'personal':
        return localizations.personalCategory;
      case 'health':
        return localizations.healthCategory;
      default:
        return category;
    }
  }

  Future<void> _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskDetailScreen()),
    );
    if (result != null && result is Task) {
      try {
        await _databaseService.createTask(result);
        _logger.i("Task added: ${result.title}");
        await _loadTasks(); // This will refresh the task list
        setState(() {}); // Trigger a rebuild of the widget
      } catch (e) {
        _logger.e("Error adding task: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add task: $e')),
          );
        }
      }
    }
  }

  Future<void> _editTask(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: _filteredTasks[index])),
    );
    if (result != null && result is Task) {
      try {
        await _databaseService.updateTask(result);
        await _notificationService.cancelHabitReminder(result.id);
        if (result.dueDate != null) {
          await _notificationService.scheduleHabitReminder(result as Habit);
        }
        _logger.i("Task updated: ${result.title}");
        await _loadTasks();
      } catch (e) {
        _logger.e("Error updating task: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update task: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteTask(int index) async {
    try {
      final taskToDelete = _filteredTasks[index];
      await _databaseService.deleteTask(taskToDelete.id);
      await _notificationService.cancelHabitReminder(taskToDelete.id);
      _logger.i("Task deleted: ${taskToDelete.title}");
      await _loadTasks();
    } catch (e) {
      _logger.e("Error deleting task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  Future<void> _completeTask(Task task) async {
    try {
      task.isCompleted = true;
      task.completedDate = DateTime.now(); // Set the completed date
      await _databaseService.updateTask(task);
      await _loadTasks();
    } catch (e) {
      _logger.e("Error completing task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete task: $e')),
        );
      }
    }
  }

  void _viewTaskDetails(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_filteredTasks[index].title),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${_filteredTasks[index].description ?? 'N/A'}'),
              Text('Due Date: ${_filteredTasks[index].dueDate?.toLocal() ?? 'N/A'}'),
              Text('Priority: ${_filteredTasks[index].priority}'),
              Text('Category: ${_filteredTasks[index].category}'),
              Text('Tags: ${_filteredTasks[index].tags.join(', ')}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}