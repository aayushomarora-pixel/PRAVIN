/// Note model representing a freeform note entity in PRAVIN's local database.
class NoteModel {
  final int? id;
  final String? title;
  final String content;
  final String createdAt;
  final String updatedAt;
  final String? folder;
  final List<String>? tags;
  final bool isFavorite;
  final bool isArchived;
  final String? color;
  final List<String>? attachments;
  final String? lastModifiedBy;
  final String? lastModifiedAt;
  final int version;

  NoteModel({
    this.id,
    this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.folder,
    this.tags,
    this.isFavorite = false,
    this.isArchived = false,
    this.color,
    this.attachments,
    this.lastModifiedBy,
    this.lastModifiedAt,
    this.version = 1,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'folder': folder,
      'tags': tags != null ? tags!.join(',') : null,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'color': color,
      'attachments': attachments != null ? attachments!.join(',') : null,
      'last_modified_by': lastModifiedBy,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  /// Create from database map
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      folder: map['folder'],
      tags: map['tags']?.split(',') ?? [],
      isFavorite: map['is_favorite'] == 1,
      isArchived: map['is_archived'] == 1,
      color: map['color'],
      attachments: map['attachments']?.split(',') ?? [],
      lastModifiedBy: map['last_modified_by'],
      lastModifiedAt: map['last_modified_at'],
      version: map['version'] ?? 1,
    );
  }

  /// Create a copy with modified fields
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? createdAt,
    String? updatedAt,
    String? folder,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    String? color,
    List<String>? attachments,
    String? lastModifiedBy,
    String? lastModifiedAt,
    int? version,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folder: folder ?? this.folder,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      color: color ?? this.color,
      attachments: attachments ?? this.attachments,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }
}