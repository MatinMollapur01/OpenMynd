import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openmynd/l10n/messages_all_locales.dart';
import '../l10n/messages_all.dart';

class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name = locale.countryCode?.isEmpty ?? false
        ? locale.languageCode
        : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle {
    return Intl.message(
      'OpenMynd',
      name: 'appTitle',
      desc: 'Title for the application',
    );
  }

  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
    );
  }

  String get darkMode {
    return Intl.message(
      'Dark Mode',
      name: 'darkMode',
    );
  }

  String get language {
    return Intl.message(
      'Language',
      name: 'language',
    );
  }

  String get selectLanguage {
    return Intl.message(
      'Select Language',
      name: 'selectLanguage',
    );
  }

  String get english {
    return Intl.message(
      'English',
      name: 'english',
    );
  }

  String get persian {
    return Intl.message(
      'Persian',
      name: 'persian',
    );
  }

  String get turkish {
    return Intl.message(
      'Turkish',
      name: 'turkish',
    );
  }

  String get azerbaijani {
    return Intl.message(
      'Azerbaijani',
      name: 'azerbaijani',
    );
  }

  String get arabic {
    return Intl.message(
      'Arabic',
      name: 'arabic',
    );
  }

  String get russian {
    return Intl.message(
      'Russian',
      name: 'russian',
    );
  }

  String get chinese {
    return Intl.message(
      'Chinese',
      name: 'chinese',
    );
  }

  String get appearance {
    return Intl.message(
      'Appearance',
      name: 'appearance',
      desc: 'Label for appearance settings',
    );
  }

  // New getters for additional translations
  String get habits {
    return Intl.message(
      'Habits',
      name: 'habits',
    );
  }

  String get addHabit {
    return Intl.message(
      'Add Habit',
      name: 'addHabit',
    );
  }

  String get editHabit {
    return Intl.message(
      'Edit Habit',
      name: 'editHabit',
    );
  }

  String get deleteHabit {
    return Intl.message(
      'Delete Habit',
      name: 'deleteHabit',
    );
  }

  String get confirmDelete {
    return Intl.message(
      'Are you sure you want to delete',
      name: 'confirmDelete',
    );
  }

  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
    );
  }

  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
    );
  }

  String get title {
    return Intl.message(
      'Title',
      name: 'title',
    );
  }

  String get description {
    return Intl.message(
      'Description',
      name: 'description',
    );
  }

  String get category {
    return Intl.message(
      'Category',
      name: 'category',
    );
  }

  String get frequency {
    return Intl.message(
      'Frequency',
      name: 'frequency',
    );
  }

  String get reminder {
    return Intl.message(
      'Reminder',
      name: 'reminder',
    );
  }

  String get color {
    return Intl.message(
      'Color',
      name: 'color',
    );
  }

  String get icon {
    return Intl.message(
      'Icon',
      name: 'icon',
    );
  }

  String get save {
    return Intl.message(
      'Save',
      name: 'save',
    );
  }

  String get streaks {
    return Intl.message(
      'Streaks',
      name: 'streaks',
    );
  }

  String get dayStreak {
    return Intl.message(
      'Day Streak',
      name: 'dayStreak',
    );
  }

  String get nextDue {
    return Intl.message(
      'Next due',
      name: 'nextDue',
    );
  }

  String get completed {
    return Intl.message(
      'Completed',
      name: 'completed',
    );
  }

  String get todo {
    return Intl.message(
      'To-Do',
      name: 'todo',
    );
  }

  String get addTask {
    return Intl.message(
      'Add Task',
      name: 'addTask',
    );
  }

  String get editTask {
    return Intl.message(
      'Edit Task',
      name: 'editTask',
    );
  }

  String get deleteTask {
    return Intl.message(
      'Delete Task',
      name: 'deleteTask',
    );
  }

  String get priority {
    return Intl.message(
      'Priority',
      name: 'priority',
    );
  }

  String get dueDate {
    return Intl.message(
      'Due Date',
      name: 'dueDate',
    );
  }

  String get tags {
    return Intl.message(
      'Tags',
      name: 'tags',
    );
  }

  String get completedTasks {
    return Intl.message(
      'Completed Tasks',
      name: 'completedTasks',
    );
  }

  String get restore {
    return Intl.message(
      'Restore',
      name: 'restore',
    );
  }

  String get search {
    return Intl.message(
      'Search',
      name: 'search',
    );
  }

  String get noTasks {
    return Intl.message(
      'No tasks found',
      name: 'noTasks',
    );
  }

  String get noHabits {
    return Intl.message(
      'No habits found',
      name: 'noHabits',
    );
  }

  String get customCategory {
    return Intl.message(
      'Custom Category',
      name: 'customCategory',
    );
  }

  String get dueTime {
    return Intl.message(
      'Due Time',
      name: 'dueTime',
      desc: 'Label for due time setting',
    );
  }

  String get updateTask {
    return Intl.message(
      'Update Task',
      name: 'updateTask',
      desc: 'Button label to update a task',
    );
  }

  String get lowPriority {
    return Intl.message('Low', name: 'lowPriority');
  }

  String get mediumPriority {
    return Intl.message('Medium', name: 'mediumPriority');
  }

  String get highPriority {
    return Intl.message('High', name: 'highPriority');
  }

  String get defaultCategory {
    return Intl.message('Default', name: 'defaultCategory');
  }

  String get workCategory {
    return Intl.message('Work', name: 'workCategory');
  }

  String get personalCategory {
    return Intl.message('Personal', name: 'personalCategory');
  }

  String get healthCategory {
    return Intl.message('Health', name: 'healthCategory');
  }

  String get fitnessCategory {
    return Intl.message('Fitness', name: 'fitnessCategory');
  }

  String get educationCategory {
    return Intl.message('Education', name: 'educationCategory');
  }

  String get dailyFrequency {
    return Intl.message('Daily', name: 'dailyFrequency');
  }

  String get weeklyFrequency {
    return Intl.message('Weekly', name: 'weeklyFrequency');
  }

  String get monthlyFrequency {
    return Intl.message('Monthly', name: 'monthlyFrequency');
  }

  String get notCompleted {
    return Intl.message(
      'Not Completed',
      name: 'notCompleted',
    );
  }

  // Add these new getters
  String get todoTab {
    return Intl.message(
      'To-Do',
      name: 'todoTab',
      desc: 'Label for the To-Do tab in the bottom navigation bar',
    );
  }

  String get habitsTab {
    return Intl.message(
      'Habits',
      name: 'habitsTab',
      desc: 'Label for the Habits tab in the bottom navigation bar',
    );
  }

  String get settingsTab {
    return Intl.message(
      'Settings',
      name: 'settingsTab',
      desc: 'Label for the Settings tab in the bottom navigation bar',
    );
  }

  String get myketAppStore {
    return Intl.message(
      'Myket App Store',
      name: 'myketAppStore',
      desc: 'Title for Myket App Store section',
    );
  }

  String get submitUserReview {
    return Intl.message(
      'Submit User Review',
      name: 'submitUserReview',
      desc: 'Button to submit a user review',
    );
  }

  String get openAppPageInMyket {
    return Intl.message(
      'Open App Page in Myket',
      name: 'openAppPageInMyket',
      desc: 'Button to open the app page in Myket',
    );
  }

  String get openDeveloperAppsPage {
    return Intl.message(
      'Open Developer\'s Apps Page',
      name: 'openDeveloperAppsPage',
      desc: 'Button to open the developer\'s apps page',
    );
  }

  // ... (rest of the class)
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fa', 'tr', 'az', 'ar', 'ru', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}