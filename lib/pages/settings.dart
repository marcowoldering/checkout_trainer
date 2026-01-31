import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.gradientBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gunmetal),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                        tooltip: 'Go back',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'SETTINGS',
                      style: GoogleFonts.chivo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pureWhite,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Settings content placeholder
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings,
                          size: 48,
                          color: AppColors.mutedGrey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Settings coming soon',
                        style: GoogleFonts.chivo(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'More options will be available\nin future updates',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedGrey.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
