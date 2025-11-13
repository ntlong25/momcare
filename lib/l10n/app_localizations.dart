import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('en'),
    Locale('vi'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'MomCare+'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @pregnancyTracking.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Tracking'**
  String get pregnancyTracking;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @daysToGo.
  ///
  /// In en, this message translates to:
  /// **'days to go'**
  String get daysToGo;

  /// No description provided for @babyDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Baby Development'**
  String get babyDevelopment;

  /// No description provided for @motherChanges.
  ///
  /// In en, this message translates to:
  /// **'What\'s Happening to Mom'**
  String get motherChanges;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @weightGainTracker.
  ///
  /// In en, this message translates to:
  /// **'Weight Gain Tracker'**
  String get weightGainTracker;

  /// No description provided for @currentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get currentWeight;

  /// No description provided for @recommendedGain.
  ///
  /// In en, this message translates to:
  /// **'Recommended Gain'**
  String get recommendedGain;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @healthDiary.
  ///
  /// In en, this message translates to:
  /// **'Health Diary'**
  String get healthDiary;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// No description provided for @addHealthLog.
  ///
  /// In en, this message translates to:
  /// **'Add Health Log'**
  String get addHealthLog;

  /// No description provided for @editHealthLog.
  ///
  /// In en, this message translates to:
  /// **'Edit Health Log'**
  String get editHealthLog;

  /// No description provided for @deleteHealthLog.
  ///
  /// In en, this message translates to:
  /// **'Delete Health Log'**
  String get deleteHealthLog;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this health log?'**
  String get confirmDelete;

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

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressure;

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get moodAnxious;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get moodEnergetic;

  /// No description provided for @moodUncomfortable.
  ///
  /// In en, this message translates to:
  /// **'Uncomfortable'**
  String get moodUncomfortable;

  /// No description provided for @latestStats.
  ///
  /// In en, this message translates to:
  /// **'Latest Stats'**
  String get latestStats;

  /// No description provided for @totalLogs.
  ///
  /// In en, this message translates to:
  /// **'Total Logs'**
  String get totalLogs;

  /// No description provided for @notTracked.
  ///
  /// In en, this message translates to:
  /// **'Not tracked'**
  String get notTracked;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @weightTrend.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend'**
  String get weightTrend;

  /// No description provided for @bloodPressureTrend.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Trend'**
  String get bloodPressureTrend;

  /// No description provided for @moodDistribution.
  ///
  /// In en, this message translates to:
  /// **'Mood Distribution'**
  String get moodDistribution;

  /// No description provided for @noWeightData.
  ///
  /// In en, this message translates to:
  /// **'No weight data available'**
  String get noWeightData;

  /// No description provided for @noBloodPressureData.
  ///
  /// In en, this message translates to:
  /// **'No blood pressure data available'**
  String get noBloodPressureData;

  /// No description provided for @noMoodData.
  ///
  /// In en, this message translates to:
  /// **'No mood data available'**
  String get noMoodData;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @addAppointment.
  ///
  /// In en, this message translates to:
  /// **'Add Appointment'**
  String get addAppointment;

  /// No description provided for @editAppointment.
  ///
  /// In en, this message translates to:
  /// **'Edit Appointment'**
  String get editAppointment;

  /// No description provided for @deleteAppointment.
  ///
  /// In en, this message translates to:
  /// **'Delete Appointment'**
  String get deleteAppointment;

  /// No description provided for @confirmDeleteAppointment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this appointment?'**
  String get confirmDeleteAppointment;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @reminderBefore.
  ///
  /// In en, this message translates to:
  /// **'Reminder Before'**
  String get reminderBefore;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @noAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments scheduled'**
  String get noAppointments;

  /// No description provided for @nutritionGuide.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Guide'**
  String get nutritionGuide;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @trimester1.
  ///
  /// In en, this message translates to:
  /// **'Trimester 1'**
  String get trimester1;

  /// No description provided for @trimester2.
  ///
  /// In en, this message translates to:
  /// **'Trimester 2'**
  String get trimester2;

  /// No description provided for @trimester3.
  ///
  /// In en, this message translates to:
  /// **'Trimester 3'**
  String get trimester3;

  /// No description provided for @postpartum.
  ///
  /// In en, this message translates to:
  /// **'Postpartum'**
  String get postpartum;

  /// No description provided for @babyFood.
  ///
  /// In en, this message translates to:
  /// **'Baby Food'**
  String get babyFood;

  /// No description provided for @noNutritionGuides.
  ///
  /// In en, this message translates to:
  /// **'No nutrition guides available'**
  String get noNutritionGuides;

  /// No description provided for @noRecipes.
  ///
  /// In en, this message translates to:
  /// **'No recipes available'**
  String get noRecipes;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @recommendedFoods.
  ///
  /// In en, this message translates to:
  /// **'Recommended Foods'**
  String get recommendedFoods;

  /// No description provided for @foodsToAvoid.
  ///
  /// In en, this message translates to:
  /// **'Foods to Avoid'**
  String get foodsToAvoid;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @nutritionBenefits.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Benefits'**
  String get nutritionBenefits;

  /// No description provided for @prepTime.
  ///
  /// In en, this message translates to:
  /// **'Prep Time'**
  String get prepTime;

  /// No description provided for @cookTime.
  ///
  /// In en, this message translates to:
  /// **'Cook Time'**
  String get cookTime;

  /// No description provided for @servings.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get servings;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @enableDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Enable dark theme'**
  String get enableDarkTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// No description provided for @pregnancyInfo.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Info'**
  String get pregnancyInfo;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @motherName.
  ///
  /// In en, this message translates to:
  /// **'Mother Name'**
  String get motherName;

  /// No description provided for @prePregnancyWeight.
  ///
  /// In en, this message translates to:
  /// **'Pre-Pregnancy Weight'**
  String get prePregnancyWeight;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @changeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Change Due Date'**
  String get changeDueDate;

  /// No description provided for @changeMotherName.
  ///
  /// In en, this message translates to:
  /// **'Change Mother Name'**
  String get changeMotherName;

  /// No description provided for @changeWeight.
  ///
  /// In en, this message translates to:
  /// **'Change Pre-Pregnancy Weight'**
  String get changeWeight;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @weightInKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightInKg;

  /// No description provided for @enterWeightInKg.
  ///
  /// In en, this message translates to:
  /// **'Enter weight in kg'**
  String get enterWeightInKg;

  /// No description provided for @dueDateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Due date updated successfully'**
  String get dueDateUpdated;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully'**
  String get nameUpdated;

  /// No description provided for @weightUpdated.
  ///
  /// In en, this message translates to:
  /// **'Weight updated successfully'**
  String get weightUpdated;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @manageYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile'**
  String get manageYourProfile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @manageYourNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage your notifications'**
  String get manageYourNotifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutMomCare.
  ///
  /// In en, this message translates to:
  /// **'About MomCare+'**
  String get aboutMomCare;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'MomCare+ is your companion app for pregnancy and postpartum health. Track your journey, get nutrition advice, and stay organized with appointments.'**
  String get appDescription;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
