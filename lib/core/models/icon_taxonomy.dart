import 'dart:convert';

class IconTaxonomyFile {
  const IconTaxonomyFile({
    required this.pack,
    required this.count,
    required this.meta,
    required this.icons,
  });

  factory IconTaxonomyFile.fromJson(String source) =>
      IconTaxonomyFile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  factory IconTaxonomyFile.fromMap(Map<String, dynamic> map) {
    final iconMap = (map['icons'] as Map? ?? const {})
        .cast<String, dynamic>()
        .map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>)
                .map((tag) => '$tag')
                .toList(growable: false),
          ),
        );

    return IconTaxonomyFile(
      pack: map['pack'] as String? ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
      meta: IconTaxonomyMeta.fromMap(
        (map['meta'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      icons: iconMap,
    );
  }

  final String pack;
  final int count;
  final IconTaxonomyMeta meta;
  final Map<String, List<String>> icons;

  List<String> tagsFor(String iconKey) => icons[iconKey] ?? const <String>[];
}

class IconTaxonomyMeta {
  const IconTaxonomyMeta({required this.generatedFrom, required this.notes});

  factory IconTaxonomyMeta.fromMap(Map<String, dynamic> map) {
    return IconTaxonomyMeta(
      generatedFrom: IconTaxonomyGeneratedFrom.fromMap(
        (map['generated_from'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      notes: (map['notes'] as List<dynamic>? ?? const [])
          .map((note) => '$note')
          .toList(growable: false),
    );
  }

  final IconTaxonomyGeneratedFrom generatedFrom;
  final List<String> notes;
}

class IconTaxonomyGeneratedFrom {
  const IconTaxonomyGeneratedFrom({
    required this.cupertinoSourceFile,
    required this.materialSourceFile,
  });

  factory IconTaxonomyGeneratedFrom.fromMap(Map<String, dynamic> map) {
    return IconTaxonomyGeneratedFrom(
      cupertinoSourceFile: map['cupertino_source_file'] as String? ?? '',
      materialSourceFile: map['material_source_file'] as String? ?? '',
    );
  }

  final String cupertinoSourceFile;
  final String materialSourceFile;
}
