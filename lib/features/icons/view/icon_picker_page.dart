import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/app_icon_entry.dart';
import '../../../core/services/icon_catalog_service.dart';
import '../../../core/widgets/page_scaffold.dart';

enum _IconPackFilter { all, material, cupertino }

enum _IconGridViewMode { detailed, compact, grouped }

@RoutePage()
class IconPickerPage extends HookWidget {
  const IconPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchController = useTextEditingController();
    final selectedFilter = useState(_IconPackFilter.all);
    final viewMode = useState(_IconGridViewMode.detailed);
    final scrollController = useScrollController();
    final catalogFuture = useMemoized(
      () => const IconCatalogService().loadCatalog(),
    );
    final catalogSnapshot = useFuture(catalogFuture);

    useListenable(searchController);

    if (catalogSnapshot.connectionState != ConnectionState.done) {
      return PageScaffold(
        title: 'Icon Picker',
        onBack: () => context.router.maybePop(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (catalogSnapshot.hasError || catalogSnapshot.data == null) {
      return PageScaffold(
        title: 'Icon Picker',
        onBack: () => context.router.maybePop(),
        body: Center(
          child: Text(
            'Failed to load icon taxonomy.',
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    final catalog = catalogSnapshot.data!;

    final query = searchController.text.trim().toLowerCase();
    final filteredEntries = _filterEntries(
      catalog: catalog,
      query: query,
      filter: selectedFilter.value,
    );
    final filteredGroups = _groupEntries(filteredEntries);

    return PageScaffold(
      title: 'Icon Picker',
      onBack: () => context.router.maybePop(),
      body: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPersistentHeader(
                delegate: _HeroHeaderDelegate(
                  totalCount: catalog.allEntries.length,
                  filteredCount: viewMode.value == _IconGridViewMode.grouped
                      ? filteredGroups.length
                      : filteredEntries.length,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ControlsHeaderDelegate(
                  colorScheme: colorScheme,
                  searchController: searchController,
                  selectedFilter: selectedFilter.value,
                  viewMode: viewMode.value,
                  onFilterSelected: (filter) => selectedFilter.value = filter,
                  onViewModeSelected: (mode) => viewMode.value = mode,
                ),
              ),
              if (viewMode.value == _IconGridViewMode.grouped
                  ? filteredGroups.isEmpty
                  : filteredEntries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _EmptyState(
                      query: searchController.text.trim(),
                      onClear: () {
                        searchController.clear();
                        selectedFilter.value = _IconPackFilter.all;
                      },
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return switch (viewMode.value) {
                          _IconGridViewMode.detailed => _IconCard(
                            entry: filteredEntries[index],
                          ),
                          _IconGridViewMode.compact => _CompactIconTile(
                            entry: filteredEntries[index],
                          ),
                          _IconGridViewMode.grouped => _GroupedIconTile(
                            group: filteredGroups[index],
                          ),
                        };
                      },
                      childCount: viewMode.value == _IconGridViewMode.grouped
                          ? filteredGroups.length
                          : filteredEntries.length,
                    ),
                    gridDelegate: switch (viewMode.value) {
                      _IconGridViewMode.detailed =>
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                      _IconGridViewMode.compact =>
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 92,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                      _IconGridViewMode.grouped =>
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 92,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap a card to copy the icon reference. Use the copy button to copy only the key.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconVariantGroup {
  const _IconVariantGroup({
    required this.groupKey,
    required this.pack,
    required this.representative,
    required this.variants,
  });

  final String groupKey;
  final IconPack pack;
  final AppIconEntry representative;
  final List<AppIconEntry> variants;
}

List<AppIconEntry> _filterEntries({
  required IconCatalog catalog,
  required String query,
  required _IconPackFilter filter,
}) {
  final entries = switch (filter) {
    _IconPackFilter.all => catalog.allEntries,
    _IconPackFilter.material => catalog.materialEntries,
    _IconPackFilter.cupertino => catalog.cupertinoEntries,
  };

  if (query.isEmpty) {
    return entries;
  }

  return entries
      .where((entry) => entry.key.toLowerCase().contains(query))
      .toList(growable: false);
}

List<_IconVariantGroup> _groupEntries(List<AppIconEntry> entries) {
  final grouped = <String, List<AppIconEntry>>{};

  for (final entry in entries) {
    final baseKey = _baseGroupKey(entry);
    final mapKey = '${entry.pack.name}:$baseKey';
    grouped.putIfAbsent(mapKey, () => <AppIconEntry>[]).add(entry);
  }

  final groups = grouped.entries
      .map((entry) {
        final variants = [...entry.value]..sort(_compareVariantEntries);
        return _IconVariantGroup(
          groupKey: _baseGroupKey(variants.first),
          pack: variants.first.pack,
          representative: _pickRepresentativeVariant(variants),
          variants: variants,
        );
      })
      .toList(growable: false);

  groups.sort((a, b) {
    final packCompare = a.pack.index.compareTo(b.pack.index);
    if (packCompare != 0) {
      return packCompare;
    }
    return a.groupKey.compareTo(b.groupKey);
  });

  return groups;
}

String _baseGroupKey(AppIconEntry entry) {
  var key = entry.key;

  if (entry.pack == IconPack.material) {
    for (final suffix in _materialVariantSuffixes) {
      if (key.endsWith(suffix)) {
        return key.substring(0, key.length - suffix.length);
      }
    }
    return key;
  }

  for (final suffix in _cupertinoVariantSuffixes) {
    if (key.endsWith(suffix)) {
      return key.substring(0, key.length - suffix.length);
    }
  }

  return key;
}

AppIconEntry _pickRepresentativeVariant(List<AppIconEntry> variants) {
  final baseKey = _baseGroupKey(variants.first);

  for (final variant in variants) {
    if (variant.key == baseKey) {
      return variant;
    }
  }

  variants.sort(_compareVariantEntries);
  return variants.first;
}

int _compareVariantEntries(AppIconEntry a, AppIconEntry b) {
  final aRank = _variantRank(a);
  final bRank = _variantRank(b);
  if (aRank != bRank) {
    return aRank.compareTo(bRank);
  }
  return a.key.compareTo(b.key);
}

int _variantRank(AppIconEntry entry) {
  final key = entry.key;
  final orderedSuffixes = entry.pack == IconPack.material
      ? _materialVariantSuffixes
      : _cupertinoVariantSuffixes;

  for (var index = 0; index < orderedSuffixes.length; index++) {
    if (key.endsWith(orderedSuffixes[index])) {
      return index + 1;
    }
  }

  return 0;
}

const _materialVariantSuffixes = <String>['_outlined', '_rounded', '_sharp'];

const _cupertinoVariantSuffixes = <String>[
  '_circle_fill',
  '_square_fill',
  '_circle',
  '_square',
  '_fill',
  '_solid',
];

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.totalCount, required this.filteredCount});

  final int totalCount;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse Flutter icons fast',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search by key, switch between packs, and copy the exact icon reference straight into your code.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _MetricPill(
                  label: 'Visible',
                  value: '$filteredCount',
                  icon: Icons.grid_view_rounded,
                ),
                _MetricPill(
                  label: 'Total',
                  value: '$totalCount',
                  icon: Icons.apps_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.searchController,
    required this.selectedFilter,
    required this.viewMode,
    required this.onFilterSelected,
    required this.onViewModeSelected,
  });

  final TextEditingController searchController;
  final _IconPackFilter selectedFilter;
  final _IconGridViewMode viewMode;
  final ValueChanged<_IconPackFilter> onFilterSelected;
  final ValueChanged<_IconGridViewMode> onViewModeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(
          controller: searchController,
          hintText: 'Search icon key',
          leading: const Icon(Icons.search),
          trailing: [
            if (searchController.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
                onPressed: searchController.clear,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FilterChip(
              label: 'All',
              icon: Icons.blur_on,
              selected: selectedFilter == _IconPackFilter.all,
              onSelected: () => onFilterSelected(_IconPackFilter.all),
            ),
            _FilterChip(
              label: 'Material',
              icon: Icons.auto_awesome_mosaic_outlined,
              selected: selectedFilter == _IconPackFilter.material,
              onSelected: () => onFilterSelected(_IconPackFilter.material),
            ),
            _FilterChip(
              label: 'Cupertino',
              icon: Icons.phone_iphone_rounded,
              selected: selectedFilter == _IconPackFilter.cupertino,
              onSelected: () => onFilterSelected(_IconPackFilter.cupertino),
            ),
            _FilterChip(
              label: 'Detailed',
              icon: Icons.view_agenda_outlined,
              selected: viewMode == _IconGridViewMode.detailed,
              onSelected: () => onViewModeSelected(_IconGridViewMode.detailed),
            ),
            _FilterChip(
              label: 'Compact',
              icon: Icons.density_small,
              selected: viewMode == _IconGridViewMode.compact,
              onSelected: () => onViewModeSelected(_IconGridViewMode.compact),
            ),
            _FilterChip(
              label: 'Grouped',
              icon: Icons.category_outlined,
              selected: viewMode == _IconGridViewMode.grouped,
              onSelected: () => onViewModeSelected(_IconGridViewMode.grouped),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeroHeaderDelegate({
    required this.totalCount,
    required this.filteredCount,
  });

  final int totalCount;
  final int filteredCount;

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => 180;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(bottom: 20 * (1 - progress)),
      child: Opacity(
        opacity: 1 - progress,
        child: Transform.translate(
          offset: Offset(0, -24 * progress),
          child: _HeroPanel(
            totalCount: totalCount,
            filteredCount: filteredCount,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeroHeaderDelegate oldDelegate) {
    return totalCount != oldDelegate.totalCount ||
        filteredCount != oldDelegate.filteredCount;
  }
}

class _ControlsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ControlsHeaderDelegate({
    required this.colorScheme,
    required this.searchController,
    required this.selectedFilter,
    required this.viewMode,
    required this.onFilterSelected,
    required this.onViewModeSelected,
  });

  final ColorScheme colorScheme;
  final TextEditingController searchController;
  final _IconPackFilter selectedFilter;
  final _IconGridViewMode viewMode;
  final ValueChanged<_IconPackFilter> onFilterSelected;
  final ValueChanged<_IconGridViewMode> onViewModeSelected;

  @override
  double get minExtent => 172;

  @override
  double get maxExtent => 172;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _ControlsPanel(
            searchController: searchController,
            selectedFilter: selectedFilter,
            viewMode: viewMode,
            onFilterSelected: onFilterSelected,
            onViewModeSelected: onViewModeSelected,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ControlsHeaderDelegate oldDelegate) {
    return selectedFilter != oldDelegate.selectedFilter ||
        viewMode != oldDelegate.viewMode ||
        searchController.text != oldDelegate.searchController.text ||
        colorScheme != oldDelegate.colorScheme;
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      showCheckmark: false,
    );
  }
}

class _IconCard extends StatelessWidget {
  const _IconCard({required this.entry});

  final AppIconEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Future<void> copyValue(String value, String label) async {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label copied: $value')));
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => copyValue(entry.reference, 'Reference'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PackBadge(pack: entry.pack),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Copy key',
                    onPressed: () => copyValue(entry.key, 'Key'),
                    icon: const Icon(Icons.content_copy_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SizedBox.expand(
                      child: Center(
                        child: Icon(
                          entry.iconData,
                          size: 38,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                entry.key,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.reference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackBadge extends StatelessWidget {
  const _PackBadge({required this.pack});

  final IconPack pack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMaterial = pack == IconPack.material;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            (isMaterial
                    ? colorScheme.primaryContainer
                    : colorScheme.tertiaryContainer)
                .withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          isMaterial ? 'Material' : 'Cupertino',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isMaterial
                ? colorScheme.onPrimaryContainer
                : colorScheme.onTertiaryContainer,
          ),
        ),
      ),
    );
  }
}

class _CompactIconTile extends StatelessWidget {
  const _CompactIconTile({required this.entry});

  final AppIconEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> copyReference() async {
      await Clipboard.setData(ClipboardData(text: entry.reference));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reference copied: ${entry.reference}')),
        );
      }
    }

    return Tooltip(
      message: '${entry.key}\n${entry.reference}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: copyReference,
          child: Center(
            child: Icon(entry.iconData, size: 38, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

class _GroupedIconTile extends StatelessWidget {
  const _GroupedIconTile({required this.group});

  final _IconVariantGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> openVariants() async {
      await showDialog<void>(
        context: context,
        builder: (context) => _VariantDialog(group: group),
      );
    }

    return Tooltip(
      message:
          '${group.groupKey}\n${group.variants.length} variants\n${group.pack.name}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openVariants,
          child: Stack(
            children: [
              Center(
                child: Icon(
                  group.representative.iconData,
                  size: 38,
                  color: colorScheme.primary,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      '${group.variants.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantDialog extends StatelessWidget {
  const _VariantDialog({required this.group});

  final _IconVariantGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(group.groupKey),
                const SizedBox(height: 4),
                Text(
                  '${group.variants.length} variants',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _PackBadge(pack: group.pack),
        ],
      ),
      content: SizedBox(
        width: 920,
        height: 560,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: group.variants.length,
          itemBuilder: (context, index) {
            return _IconCard(entry: group.variants[index]);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40),
              const SizedBox(height: 12),
              Text(
                'No icons match "${query.isEmpty ? 'your filters' : query}"',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a broader key search or reset the current filters.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
