import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import 'package:logger/logger.dart';

class CompletedTasksScreen extends StatefulWidget {
  final VoidCallback onTaskRestored;

  const CompletedTasksScreen({super.key, required this.onTaskRestored});

  @override
  CompletedTasksScreenState createState() => CompletedTasksScreenState();
}

class CompletedTasksScreenState extends State<CompletedTasksScreen> {
  List<Task> _completedTasks = [];
  final DatabaseService _databaseService = DatabaseService.instance;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {
    try {
      final tasks = await _databaseService.readCompletedTasks();
      setState(() {
        _completedTasks = tasks;
      });
      _logger.i("Loaded ${tasks.length} completed tasks");
    } catch (e) {
      _logger.e("Error loading completed tasks: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load completed tasks: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
      ),
      body: ListView.builder(
        itemCount: _completedTasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_completedTasks[index].title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Added Date: ${_completedTasks[index].id}'),
                Text('Done Date: ${_completedTasks[index].completedDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}'), // Display the completed date
                Wrap(
                  spacing: 4,
                  children: _completedTasks[index].tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () => _restoreTask(_completedTasks[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _restoreTask(Task task) async {
    try {
      task.isCompleted = false;
      await _databaseService.updateTask(task);
      widget.onTaskRestored();
      await _loadCompletedTasks();
    } catch (e) {
      _logger.e("Error restoring task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore task: $e')),
        );
      }
    }
  }
}