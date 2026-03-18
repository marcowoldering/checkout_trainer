import 'package:checout_trainer/pages/checkouts.dart';
import 'package:checout_trainer/pages/home.dart';
import 'package:checout_trainer/pages/settings.dart';
import 'package:checout_trainer/pages/trainer.dart';
import 'package:checout_trainer/pages/statistics.dart';
import 'package:checout_trainer/pages/profile.dart';
import 'package:checout_trainer/repositories/custom_checkout_repository.dart';
import 'package:checout_trainer/repositories/settings_repository.dart';
import 'package:checout_trainer/repositories/statistics_repository.dart';
import 'package:checout_trainer/repositories/gamification_repository.dart';
import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CustomCheckoutRepository()),
          ChangeNotifierProvider(create: (_) => SettingsRepository()),
          ChangeNotifierProvider(create: (_) => StatisticsRepository()),
          ChangeNotifierProvider(create: (_) => GamificationRepository()),
        ],
        child: MyApp(),
      ),
    );
  });

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Checkout Trainer',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/trainer': (context) => TrainerPage(),
        '/checkouts': (context) => CheckoutsPage(),
        '/settings': (context) => SettingsPage(),
        '/statistics': (context) => StatisticsPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
