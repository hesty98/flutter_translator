import 'package:flutter/widgets.dart';

enum IconPack { material, cupertino }

class AppIconEntry {
  final String key;
  final String reference;
  final IconData iconData;
  final IconPack pack;
  final List<String> tags;

  const AppIconEntry({
    required this.key,
    required this.reference,
    required this.iconData,
    required this.pack,
    this.tags = const [],
  });

  AppIconEntry copyWith({
    String? key,
    String? reference,
    IconData? iconData,
    IconPack? pack,
    List<String>? tags,
  }) {
    return AppIconEntry(
      key: key ?? this.key,
      reference: reference ?? this.reference,
      iconData: iconData ?? this.iconData,
      pack: pack ?? this.pack,
      tags: tags ?? this.tags,
    );
  }
}
