import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

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
      print("Loaded ${tasks.length} tasks");
    } catch (e) {
      print("Error loading tasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
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
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search tasks',
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
                  title: Text(_filteredTasks[index].title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_filteredTasks[index].description ?? ''),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskDetailScreen()),
    );
    if (result != null && result is Task) {
      try {
        await _databaseService.createTask(result);
        if (result.dueDate != null) {
          await _notificationService.scheduleNotification(
            result.id,
            result.title,
            result.description ?? 'Task due',
            result.dueDate!,
          );
        }
        print("Task added: ${result.title}");
        await _loadTasks(); // Reload tasks after adding
      } catch (e) {
        print("Error adding task: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }

  void _editTask(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: _filteredTasks[index])),
    );
    if (result != null && result is Task) {
      try {
        await _databaseService.updateTask(result);
        await _notificationService.cancelNotification(result.id.hashCode);
        if (result.dueDate != null) {
          await _notificationService.scheduleNotification(
            result.id,
            result.title,
            result.description ?? 'Task due',
            result.dueDate!,
          );
        }
        print("Task updated: ${result.title}");
        await _loadTasks(); // Reload tasks after editing
      } catch (e) {
        print("Error updating task: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  void _deleteTask(int index) async {
    try {
      final taskToDelete = _filteredTasks[index];
      await _databaseService.deleteTask(taskToDelete.id);
      // Instead of parsing the ID, use a unique integer for the notification
      await _notificationService.cancelNotification(taskToDelete.id.hashCode);
      print("Task deleted: ${taskToDelete.title}");
      await _loadTasks(); // Reload tasks after deleting
    } catch (e) {
      print("Error deleting task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $e')),
      );
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