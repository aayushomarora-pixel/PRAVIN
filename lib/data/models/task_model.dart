/// Task model representing a task entity in PRAVIN's local database.
class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final String? dueDate;
  final String? priority;
  final String status;
  final String createdAt;
  final String updatedAt;
  final bool reminderEnabled;
  final String? reminderTime;
  final String? completedAt;
  final String? folder;
  final List<String>? tags;
  final String? recurrence;
  final String? estimatedTime;
  final String? location;
  final List<String>? attachments;
  final String? color;
  final bool isFavorite;
  final bool isArchived;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.status = 'todo',
    required this.createdAt,
    required this.updatedAt,
    this.reminderEnabled = false,
    this.reminderTime,
    this.completedAt,
    this.folder,
    this.tags,
    this.recurrence,
    this.estimatedTime,
    this.location,
    this.attachments,
    this.color,
    this.isFavorite = false,
    this.isArchived = false,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'priority': priority,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'completed_at': completedAt,
      'folder': folder,
      'tags': tags != null ? tags!.join(',') : null,
      'recurrence': recurrence,
      'estimated_time': estimatedTime,
      'location': location,
      'attachments': attachments != null ? attachments!.join(',') : null,
      'color': color,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  /// Create from database map
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['due_date'],
      priority: map['priority'],
      status: map['status'] ?? 'todo',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      reminderEnabled: map['reminder_enabled'] == 1,
      reminderTime: map['reminder_time'],
      completedAt: map['completed_at'],
      folder: map['folder'],
      tags: map['tags']?.split(',') ?? [],
      recurrence: map['recurrence'],
      estimatedTime: map['estimated_time'],
      location: map['location'],
      attachments: map['attachments']?.split(',') ?? [],
      color: map['color'],
      isFavorite: map['is_favorite'] == 1,
      isArchived: map['is_archived'] == 1,
    );
  }

  /// Create a copy with modified fields
  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    String? priority,
    String? status,
    String? createdAt,
    String? updatedAt,
    bool? reminderEnabled,
    String? reminderTime,
    String? completedAt,
    String? folder,
    List<String>? tags,
    String? recurrence,
    String? estimatedTime,
    String? location,
    List<String>? attachments,
    String? color,
    bool? isFavorite,
    bool? isArchived,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      completedAt: completedAt ?? this.completedAt,
      folder: folder ?? this.folder,
      tags: tags ?? this.tags,
      recurrence: recurrence ?? this.recurrence,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      location: location ?? this.location,
      attachments: attachments ?? this.attachments,
      color: color ?? this.color,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
