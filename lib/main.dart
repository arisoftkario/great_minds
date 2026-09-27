import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/app_data_service.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'views/public/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize French locale date formatting for intl
  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    debugPrint('Date formatting initialization error: $e');
  }

  // Initialize persistence, auth, and language detection
  await AppDataService().init();
  await AuthService().init();
  await LanguageService().init();

  runApp(const GreatMindsApp());
}

class GreatMindsApp extends StatelessWidget {
  const GreatMindsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        final currentLang = LanguageService().currentLanguage;
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: Locale(currentLang),
          home: const HomePage(),
        );
      },
    );
  }
}
