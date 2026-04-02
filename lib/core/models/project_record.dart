import 'dart:convert';

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.title,
    required this.directoryPath,
    required this.defaultLocaleTag,
    this.arbFilePrefix = 'app',
    this.directoryBookmark,
  });

  final String id;
  final String title;
  final String directoryPath;
  final String defaultLocaleTag;
  final String arbFilePrefix;
  final String? directoryBookmark;

  ProjectRecord copyWith({
    String? id,
    String? title,
    String? directoryPath,
    String? defaultLocaleTag,
    String? arbFilePrefix,
    String? directoryBookmark,
    bool clearDirectoryBookmark = false,
  }) {
    return ProjectRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      directoryPath: directoryPath ?? this.directoryPath,
      defaultLocaleTag: defaultLocaleTag ?? this.defaultLocaleTag,
      arbFilePrefix: arbFilePrefix ?? this.arbFilePrefix,
      directoryBookmark: clearDirectoryBookmark
          ? null
          : directoryBookmark ?? this.directoryBookmark,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'directoryPath': directoryPath,
      'defaultLocaleTag': defaultLocaleTag,
      'arbFilePrefix': arbFilePrefix,
      'directoryBookmark': directoryBookmark,
    };
  }

  factory ProjectRecord.fromMap(Map<String, dynamic> map) {
    return ProjectRecord(
      id: map['id'] as String,
      title: map['title'] as String,
      directoryPath: map['directoryPath'] as String,
      defaultLocaleTag: map['defaultLocaleTag'] as String? ?? 'en',
      arbFilePrefix: map['arbFilePrefix'] as String? ?? 'app',
      directoryBookmark: map['directoryBookmark'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ProjectRecord.fromJson(String source) {
    return ProjectRecord.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
