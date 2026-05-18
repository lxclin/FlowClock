class Task {
  final int? id;
  final String title;
  final int completedPomodoros;
  final String? note;
  final bool isArchived;
  final int sortOrder;
  final int targetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    this.id,
    required this.title,
    this.completedPomodoros = 0,
    this.note,
    this.isArchived = false,
    this.sortOrder = 0,
    this.targetMinutes = 25,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      completedPomodoros: map['completed_pomodoros'] as int? ?? 0,
      note: map['note'] as String?,
      isArchived: (map['is_archived'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      targetMinutes: (map['target_minutes'] as int?) ?? 25,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Task copyWith({
    int? id,
    String? title,
    int? completedPomodoros,
    String? note,
    bool? isArchived,
    int? sortOrder,
    int? targetMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      note: note ?? this.note,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
