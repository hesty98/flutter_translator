import 'package:flutter/material.dart';

import '../utils/locale_utils.dart';

class LocaleBadge extends StatelessWidget {
  const LocaleBadge({required this.localeTagValue, super.key});

  final String localeTagValue;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(flagForLocaleTag(localeTagValue)),
      label: Text(localeTagValue),
      visualDensity: VisualDensity.compact,
    );
  }
}
