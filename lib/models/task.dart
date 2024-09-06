class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final String category;
  final List<String> tags;
  bool isCompleted;
  DateTime? completedDate;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    required this.category,
    this.tags = const [],
    this.isCompleted = false,
    this.completedDate,
  });

  // Add these methods for JSON serialization/deserialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'tags': tags.join(','), // Convert list to comma-separated string
      'isCompleted': isCompleted ? 1 : 0, // Convert bool to int
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'],
      category: json['category'],
      tags: (json['tags'] as String).split(','), // Convert comma-separated string to list
      isCompleted: json['isCompleted'] == 1, // Convert int to bool
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
    );
  }
}