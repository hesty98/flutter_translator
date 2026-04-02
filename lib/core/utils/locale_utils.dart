import 'package:flutter/material.dart';

String localeTag(Locale locale) {
  final countryCode = locale.countryCode;
  return countryCode == null || countryCode.isEmpty
      ? locale.languageCode
      : '${locale.languageCode}_$countryCode';
}

Locale localeFromTag(String value) {
  final parts = value.replaceAll('-', '_').split('_');
  return parts.length == 1
      ? Locale(parts.first)
      : Locale(parts.first, parts[1]);
}

String flagForLocaleTag(String localeTagValue) {
  final locale = localeFromTag(localeTagValue);
  final countryCode =
      (locale.countryCode ?? _fallbackCountry(locale.languageCode))
          .toUpperCase();
  if (countryCode.length != 2) {
    return locale.languageCode.toUpperCase();
  }

  return countryCode.runes
      .map((char) => String.fromCharCode(char + 127397))
      .join();
}

String _fallbackCountry(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'en':
      return 'US';
    case 'de':
      return 'DE';
    case 'es':
      return 'ES';
    case 'fr':
      return 'FR';
    case 'it':
      return 'IT';
    case 'pt':
      return 'PT';
    case 'ja':
      return 'JP';
    case 'ko':
      return 'KR';
    case 'zh':
      return 'CN';
    case 'nl':
      return 'NL';
    case 'pl':
      return 'PL';
    default:
      return languageCode.padRight(2, ' ').substring(0, 2);
  }
}
