import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/habit.dart';
import 'package:openmynd/l10n/app_localizations.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? AppLocalizations.of(context).addHabit : AppLocalizations.of(context).editHabit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).title,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).description,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).category,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'Personal', child: Text(AppLocalizations.of(context).personalCategory)),
                  DropdownMenuItem(value: 'Work', child: Text(AppLocalizations.of(context).workCategory)),
                  DropdownMenuItem(value: 'Health', child: Text(AppLocalizations.of(context).healthCategory)),
                  DropdownMenuItem(value: 'Fitness', child: Text(AppLocalizations.of(context).fitnessCategory)),
                  DropdownMenuItem(value: 'Education', child: Text(AppLocalizations.of(context).educationCategory)),
                  DropdownMenuItem(value: 'Custom', child: Text(AppLocalizations.of(context).customCategory)),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              if (_selectedCategory == 'Custom')
                const SizedBox(height: 16),
              if (_selectedCategory == 'Custom')
                TextFormField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).customCategory,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedCategory == 'Custom' && (value == null || value.isEmpty)) {
                      return 'Please enter a custom category';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitFrequency>(
                value: _selectedFrequency,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).frequency,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: HabitFrequency.daily, child: Text(AppLocalizations.of(context).dailyFrequency)),
                  DropdownMenuItem(value: HabitFrequency.weekly, child: Text(AppLocalizations.of(context).weeklyFrequency)),
                  DropdownMenuItem(value: HabitFrequency.monthly, child: Text(AppLocalizations.of(context).monthlyFrequency)),
                ],
                onChanged: (HabitFrequency? newValue) {
                  setState(() {
                    _selectedFrequency = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).icon, style: const TextStyle(fontSize: 16)),
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
                title: Text(AppLocalizations.of(context).color),
                trailing: Container(
                  width: 24,
                  height: 24,
                  color: _selectedColor,
                ),
                onTap: _pickColor,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveHabit,
                child: Text(widget.habit == null ? AppLocalizations.of(context).addHabit : AppLocalizations.of(context).editHabit),
              ),
            ],
          ),
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

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      final habit = Habit(
        id: widget.habit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory == 'Custom' ? _customCategoryController.text : _selectedCategory,
        frequency: _selectedFrequency,
        icon: _selectedIcon,
        color: _selectedColor,
        createdAt: widget.habit?.createdAt ?? DateTime.now(),
        completionStatus: widget.habit?.completionStatus ?? [],
        notes: widget.habit?.notes ?? [],
        isCompletedToday: widget.habit?.isCompletedToday ?? false,
        lastCompletionTime: widget.habit?.lastCompletionTime,
        nextDueTime: widget.habit?.nextDueTime,
      );

      print('Saving habit: ${habit.toJson()}'); // Add this line for debugging

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