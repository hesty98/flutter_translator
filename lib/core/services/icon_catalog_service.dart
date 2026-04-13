import 'package:flutter/services.dart';

import '../app_icon_entry.dart';
import '../generated/cupertino_icon_pack.dart';
import '../generated/material_icon_pack.dart';
import '../models/icon_taxonomy.dart';

class IconCatalog {
  const IconCatalog({
    required this.materialTaxonomy,
    required this.cupertinoTaxonomy,
    required this.materialEntries,
    required this.cupertinoEntries,
  });

  final IconTaxonomyFile materialTaxonomy;
  final IconTaxonomyFile cupertinoTaxonomy;
  final List<AppIconEntry> materialEntries;
  final List<AppIconEntry> cupertinoEntries;

  List<AppIconEntry> get allEntries => <AppIconEntry>[
    ...materialEntries,
    ...cupertinoEntries,
  ];
}

class IconCatalogService {
  static const _materialTaxonomyAsset =
      'lib/core/generated/material_icon_taxonomy.json';
  static const _cupertinoTaxonomyAsset =
      'lib/core/generated/cupertino_icon_taxonomy.json';

  const IconCatalogService();

  Future<IconCatalog> loadCatalog() async {
    final materialTaxonomy = await _loadTaxonomy(_materialTaxonomyAsset);
    final cupertinoTaxonomy = await _loadTaxonomy(_cupertinoTaxonomyAsset);

    return IconCatalog(
      materialTaxonomy: materialTaxonomy,
      cupertinoTaxonomy: cupertinoTaxonomy,
      materialEntries: _mergeTags(materialIconEntries, materialTaxonomy),
      cupertinoEntries: _mergeTags(cupertinoIconEntries, cupertinoTaxonomy),
    );
  }

  Future<IconTaxonomyFile> _loadTaxonomy(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    return IconTaxonomyFile.fromJson(source);
  }

  List<AppIconEntry> _mergeTags(
    List<AppIconEntry> entries,
    IconTaxonomyFile taxonomy,
  ) {
    return entries
        .map((entry) => entry.copyWith(tags: taxonomy.tagsFor(entry.key)))
        .toList(growable: false);
  }
}
