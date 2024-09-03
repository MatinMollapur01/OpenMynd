import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart'; // Add this line

class HabitDetailScreen extends StatefulWidget {
  final Habit? habit;

  const HabitDetailScreen({super.key, this.habit});

  @override
  HabitDetailScreenState createState() => HabitDetailScreenState();
}

class HabitDetailScreenState extends State<HabitDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  TimeOfDay? _reminderTime;
  late TextEditingController _notesController;
  late String _category;
  final List<String> _categories = ['Health', 'Productivity', 'Personal', 'Other'];
  late HabitFrequency _frequency;
  List<int> _customDays = [];

  // Add this list of predefined icons
  final List<IconData> _iconOptions = [
    Icons.star,
    Icons.favorite,
    Icons.fitness_center,
    Icons.book,
    Icons.music_note,
    Icons.brush,
    Icons.restaurant,
    Icons.directions_run,
    Icons.local_drink,
    Icons.timer,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');
    _selectedIcon = widget.habit?.icon ?? Icons.star;
    _selectedColor = widget.habit?.color ?? Colors.blue;
    _reminderTime = widget.habit?.reminderTime;
    _notesController = TextEditingController(text: widget.habit?.notes.join('\n') ?? '');
    _category = widget.habit?.category ?? _categories.first;
    _frequency = widget.habit?.frequency ?? HabitFrequency.daily;
    _customDays = widget.habit?.customDays ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit'),
        actions: [
          if (widget.habit != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('Select Icon:', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: _iconOptions.map((IconData icon) {
                return IconButton(
                  icon: Icon(icon),
                  color: _selectedIcon == icon ? _selectedColor : null,
                  onPressed: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickColor,
              child: const Text('Pick Color'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_reminderTime == null ? 'Set Reminder' : 'Reminder: ${_reminderTime!.format(context)}'),
              trailing: const Icon(Icons.alarm),
              onTap: _pickReminderTime,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _category = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HabitFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: HabitFrequency.values.map((freq) {
                return DropdownMenuItem<HabitFrequency>(
                  value: freq,
                  child: Text(freq.toString().split('.').last),
                );
              }).toList(),
              onChanged: (HabitFrequency? newValue) {
                setState(() {
                  _frequency = newValue!;
                });
              },
            ),
            if (_frequency == HabitFrequency.custom)
              _buildCustomDaysPicker(),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveHabit,
              child: Text(widget.habit == null ? 'Add Habit' : 'Update Habit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDaysPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Select custom days:'),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1;
            return FilterChip(
              label: Text(DateFormat('E').format(DateTime(2023, 1, day))),
              selected: _customDays.contains(day),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _customDays.add(day);
                  } else {
                    _customDays.remove(day);
                  }
                });
              },
            );
          }),
        ),
      ],
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
              labelTypes: const [], // Use empty list to disable label
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
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _reminderTime = pickedTime;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: const Text('Are you sure you want to delete this habit?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteHabit();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteHabit() {
    if (widget.habit != null) {
      Navigator.of(context).pop({'action': 'delete', 'habit': widget.habit});
    }
  }

  void _saveHabit() {
    final habit = Habit(
      id: widget.habit?.id ?? DateTime.now().toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      icon: _selectedIcon,
      color: _selectedColor,
      category: _category, // Add this line
      completionStatus: widget.habit?.completionStatus ?? [],
      createdAt: widget.habit?.createdAt ?? DateTime.now(),
      notes: _notesController.text.split('\n'),
      reminderTime: _reminderTime,
      frequency: _frequency,
      customDays: _frequency == HabitFrequency.custom ? _customDays : null,
    );
    Navigator.of(context).pop(habit);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}