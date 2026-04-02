// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Translator';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get addProject => 'Add project';

  @override
  String get editProject => 'Edit project';

  @override
  String get projectTitleLabel => 'Project title';

  @override
  String get projectDirectoryLabel => 'Project directory';

  @override
  String get chooseDirectory => 'Choose directory';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noProjects => 'No projects yet';

  @override
  String get noProjectsHint =>
      'Add a project directory with ARB files to start editing translations.';

  @override
  String get defaultLanguage => 'Default language';

  @override
  String get addLanguage => 'Add language';

  @override
  String get openTranslations => 'Open translations';

  @override
  String get translationStatus => 'Translation status';

  @override
  String get languagesToDisplay => 'Languages to display';

  @override
  String get statusFilter => 'Status';

  @override
  String get searchHint => 'Search key or text';

  @override
  String get allStatuses => 'All';

  @override
  String get translated => 'Translated';

  @override
  String get notTranslated => 'Not translated';

  @override
  String get needsReview => 'Needs review';

  @override
  String get savedTranslation => 'Translation saved';

  @override
  String get savedStatus => 'Status saved';

  @override
  String get languageCode => 'Language code';

  @override
  String get projectDetails => 'Project details';

  @override
  String get translationsTitle => 'Translations';

  @override
  String get emptyTranslations => 'No strings match the active filters.';

  @override
  String get baseLanguage => 'Base language';

  @override
  String get directoryRequired => 'Choose a directory.';

  @override
  String get titleRequired => 'Enter a project title.';

  @override
  String get languageRequired => 'Enter a language code such as en or de_DE.';

  @override
  String get projectRemoved => 'Project removed';

  @override
  String get languageAdded => 'Language added';

  @override
  String get stringAdded => 'String added';

  @override
  String get stringDeleted => 'String deleted';

  @override
  String get statusLabel => 'Status';

  @override
  String get keyLabel => 'Key';

  @override
  String get translatedPercent => 'Translated %';

  @override
  String get languagesColumn => 'Languages';

  @override
  String get originalText => 'Original text';

  @override
  String get addString => 'Add string';

  @override
  String get deleteString => 'Delete string';

  @override
  String get stringKeyLabel => 'String key';

  @override
  String get baseValueLabel => 'Base value';

  @override
  String get existingStrings => 'Strings';

  @override
  String get noStrings => 'No strings yet';

  @override
  String get deleteStringPrompt =>
      'Delete this string from all language files?';

  @override
  String get stringKeyRequired => 'Enter a string key.';

  @override
  String get stringExists => 'A string with this key already exists.';

  @override
  String get projectPathMissing => 'Project directory is not available.';

  @override
  String get noLanguages =>
      'No ARB languages found. Add one to create the first file.';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';
}
