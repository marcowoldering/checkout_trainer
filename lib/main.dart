import 'package:checout_trainer/pages/checkouts.dart';
import 'package:checout_trainer/pages/home.dart';
import 'package:checout_trainer/pages/settings.dart';
import 'package:checout_trainer/pages/trainer.dart';
import 'package:checout_trainer/repositories/custom_checkout_repository.dart';
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
      ChangeNotifierProvider(
        create: (_) => CustomCheckoutRepository(),
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
      },
    );
  }
}
