import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  AddEditHabitScreenState createState() => AddEditHabitScreenState();
}

class AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _customCategoryController;
  String _selectedCategory = 'Personal';
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  IconData _selectedIcon = Icons.star;
  Color _selectedColor = Colors.blue;
  TimeOfDay? _reminderTime;

  final List<String> _categories = ['Personal', 'Work', 'Health', 'Fitness', 'Education', 'Custom'];
  
  final List<IconData> _icons = [
    Icons.fitness_center, // Fitness
    Icons.book,           // Education
    Icons.work,           // Work
    Icons.favorite,       // Health
    Icons.music_note,     // Personal
    Icons.local_dining,   // Health/Personal
    Icons.code,           // Work/Education
    Icons.brush,          // Personal
    Icons.directions_run, // Fitness
    Icons.school,         // Education
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');
    _customCategoryController = TextEditingController();
    if (widget.habit != null) {
      _selectedCategory = widget.habit!.category;
      _selectedFrequency = widget.habit!.frequency;
      _selectedIcon = widget.habit!.icon;
      _selectedColor = widget.habit!.color;
      _reminderTime = widget.habit!.reminderTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            if (_selectedCategory == 'Custom')
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(labelText: 'Custom Category'),
                validator: (value) {
                  if (_selectedCategory == 'Custom' && (value == null || value.isEmpty)) {
                    return 'Please enter a custom category';
                  }
                  return null;
                },
              ),
            DropdownButtonFormField<HabitFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: HabitFrequency.values.map((HabitFrequency frequency) {
                return DropdownMenuItem<HabitFrequency>(
                  value: frequency,
                  child: Text(frequency.toString().split('.').last),
                );
              }).toList(),
              onChanged: (HabitFrequency? newValue) {
                setState(() {
                  _selectedFrequency = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Select an icon:', style: TextStyle(fontSize: 16)),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _icons.map((IconData icon) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIcon == icon ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 32),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Color'),
              trailing: Container(
                width: 24,
                height: 24,
                color: _selectedColor,
              ),
              onTap: _pickColor,
            ),
            ListTile(
              title: const Text('Reminder'),
              subtitle: Text(_reminderTime != null 
                ? 'Set for ${_reminderTime!.format(context)}'
                : 'Not set'),
              trailing: _reminderTime != null
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _reminderTime = null;
                      });
                    },
                  )
                : null,
              onTap: _pickReminderTime,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveHabit,
              child: Text(widget.habit == null ? 'Add Habit' : 'Update Habit'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      final habit = Habit(
        id: widget.habit?.id ?? DateTime.now().toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory == 'Custom' ? _customCategoryController.text : _selectedCategory,
        frequency: _selectedFrequency,
        icon: _selectedIcon,
        color: _selectedColor,
        reminderTime: _reminderTime,
        createdAt: widget.habit?.createdAt ?? DateTime.now(),
        completionStatus: widget.habit?.completionStatus ?? [],
      );

      if (_reminderTime != null) {
        NotificationService().scheduleHabitReminder(habit);
      } else if (widget.habit?.reminderTime != null) {
        NotificationService().cancelHabitReminder(habit.id);
      }

      Navigator.pop(context, habit);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }
}