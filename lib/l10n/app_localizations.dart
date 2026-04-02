import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter Translator'**
  String get appTitle;

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @projectTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Project title'**
  String get projectTitleLabel;

  /// No description provided for @projectDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Project directory'**
  String get projectDirectoryLabel;

  /// No description provided for @chooseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose directory'**
  String get chooseDirectory;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjects;

  /// No description provided for @noProjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a project directory with ARB files to start editing translations.'**
  String get noProjectsHint;

  /// No description provided for @defaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default language'**
  String get defaultLanguage;

  /// No description provided for @addLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get addLanguage;

  /// No description provided for @openTranslations.
  ///
  /// In en, this message translates to:
  /// **'Open translations'**
  String get openTranslations;

  /// No description provided for @translationStatus.
  ///
  /// In en, this message translates to:
  /// **'Translation status'**
  String get translationStatus;

  /// No description provided for @languagesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'Languages to display'**
  String get languagesToDisplay;

  /// No description provided for @statusFilter.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusFilter;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search key or text'**
  String get searchHint;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allStatuses;

  /// No description provided for @translated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get translated;

  /// No description provided for @notTranslated.
  ///
  /// In en, this message translates to:
  /// **'Not translated'**
  String get notTranslated;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get needsReview;

  /// No description provided for @savedTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation saved'**
  String get savedTranslation;

  /// No description provided for @savedStatus.
  ///
  /// In en, this message translates to:
  /// **'Status saved'**
  String get savedStatus;

  /// No description provided for @languageCode.
  ///
  /// In en, this message translates to:
  /// **'Language code'**
  String get languageCode;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project details'**
  String get projectDetails;

  /// No description provided for @translationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get translationsTitle;

  /// No description provided for @emptyTranslations.
  ///
  /// In en, this message translates to:
  /// **'No strings match the active filters.'**
  String get emptyTranslations;

  /// No description provided for @baseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Base language'**
  String get baseLanguage;

  /// No description provided for @directoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a directory.'**
  String get directoryRequired;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a project title.'**
  String get titleRequired;

  /// No description provided for @languageRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a language code such as en or de_DE.'**
  String get languageRequired;

  /// No description provided for @projectRemoved.
  ///
  /// In en, this message translates to:
  /// **'Project removed'**
  String get projectRemoved;

  /// No description provided for @languageAdded.
  ///
  /// In en, this message translates to:
  /// **'Language added'**
  String get languageAdded;

  /// No description provided for @stringAdded.
  ///
  /// In en, this message translates to:
  /// **'String added'**
  String get stringAdded;

  /// No description provided for @stringDeleted.
  ///
  /// In en, this message translates to:
  /// **'String deleted'**
  String get stringDeleted;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @keyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get keyLabel;

  /// No description provided for @translatedPercent.
  ///
  /// In en, this message translates to:
  /// **'Translated %'**
  String get translatedPercent;

  /// No description provided for @languagesColumn.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesColumn;

  /// No description provided for @originalText.
  ///
  /// In en, this message translates to:
  /// **'Original text'**
  String get originalText;

  /// No description provided for @addString.
  ///
  /// In en, this message translates to:
  /// **'Add string'**
  String get addString;

  /// No description provided for @deleteString.
  ///
  /// In en, this message translates to:
  /// **'Delete string'**
  String get deleteString;

  /// No description provided for @stringKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'String key'**
  String get stringKeyLabel;

  /// No description provided for @baseValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Base value'**
  String get baseValueLabel;

  /// No description provided for @existingStrings.
  ///
  /// In en, this message translates to:
  /// **'Strings'**
  String get existingStrings;

  /// No description provided for @noStrings.
  ///
  /// In en, this message translates to:
  /// **'No strings yet'**
  String get noStrings;

  /// No description provided for @deleteStringPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete this string from all language files?'**
  String get deleteStringPrompt;

  /// No description provided for @stringKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a string key.'**
  String get stringKeyRequired;

  /// No description provided for @stringExists.
  ///
  /// In en, this message translates to:
  /// **'A string with this key already exists.'**
  String get stringExists;

  /// No description provided for @projectPathMissing.
  ///
  /// In en, this message translates to:
  /// **'Project directory is not available.'**
  String get projectPathMissing;

  /// No description provided for @noLanguages.
  ///
  /// In en, this message translates to:
  /// **'No ARB languages found. Add one to create the first file.'**
  String get noLanguages;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
