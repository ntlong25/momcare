import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/encryption_service.dart';
import 'core/services/health_service.dart';
import 'core/services/maternal_habit_service.dart';
import 'core/services/appointment_reminder_service.dart';
import 'core/utils/app_logger.dart';
import 'core/data/content_pack_service.dart';
import 'core/data/pregnancy_weeks_data.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/home/screens/main_navigation.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/mode_selection_screen.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  try {
    await DatabaseService.init();
  } on EncryptionUnavailableException catch (e) {
    // Existing encrypted data could not be unlocked. Do not open the boxes
    // unencrypted (that could corrupt them); ask the user to restart instead.
    AppLogger.instance.fatal('Secure storage unavailable', error: e);
    runApp(const _StartupErrorApp());
    return;
  }
  await ContentPackService.init();
  PregnancyWeeksDatabase.setContentPack(ContentPackService.pregnancyWeeks);

  try {
    await NotificationService.init();
  } catch (e, stackTrace) {
    AppLogger.instance.error(
      'Notification init failed',
      error: e,
      stackTrace: stackTrace,
    );
  }

  runApp(const ProviderScope(child: MyApp()));

  // Non-blocking background work after the first frame is scheduled.
  unawaited(HealthService.init());
  unawaited(_rescheduleReminders());
}

Future<void> _rescheduleReminders() async {
  try {
    await MaternalHabitService.rescheduleEnabledReminders();
    await AppointmentReminderService.rescheduleAll();
  } catch (e, stackTrace) {
    AppLogger.instance.warning(
      'Could not reschedule reminders',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64),
                SizedBox(height: 16),
                Text(
                  'Không thể mở dữ liệu được bảo vệ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Dữ liệu của bạn vẫn còn trên thiết bị. Vui lòng đóng hẳn ứng dụng và mở lại. Nếu lỗi vẫn tiếp diễn, hãy khởi động lại điện thoại.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'MomCare+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi')],
      home: const SplashScreen(nextScreen: AppInitializer()),
    );
  }
}

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);

    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MomCare+',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        final hasCompletedOnboarding = snapshot.data ?? false;

        // If not completed onboarding, show onboarding screen
        if (!hasCompletedOnboarding) {
          return const OnboardingScreen();
        }

        // If no mode selected yet, show mode selection
        if (appMode == null) {
          return const ModeSelectionScreen();
        }

        // Otherwise show main navigation
        return const MainNavigation();
      },
    );
  }

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.onboardingKey) ?? false;
  }
}
