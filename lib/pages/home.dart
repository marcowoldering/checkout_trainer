import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.gradientBackground,
        child: Stack(
          children: [
            // Subtle radial glow accent
            Positioned(
              bottom: -100,
              left: 0,
              right: 0,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      AppColors.crimsonRed.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Glass-style title card with gold border glow
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 32,
                      ),
                      decoration: AppDecorations.glassCard,
                      child: Column(
                        children: [
                          Text(
                            "CHECKOUT",
                            style: GoogleFonts.chivo(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pureWhite,
                              letterSpacing: 4,
                            ),
                          ),
                          Text(
                            "TRAINER",
                            style: GoogleFonts.chivo(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amberGold,
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
                    // Premium gradient buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          _buildPremiumButton(
                            context,
                            icon: Icons.sports,
                            label: "Start Training",
                            onPressed: () {
                              Navigator.pushNamed(context, '/trainer');
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPremiumButton(
                            context,
                            icon: Icons.view_list,
                            label: "Checkouts",
                            onPressed: () {
                              Navigator.pushNamed(context, '/checkouts');
                            },
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: isPrimary ? AppColors.crimsonGradient : null,
        color: isPrimary ? null : AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? AppColors.crimsonRed.withOpacity(0.4)
                : Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: isPrimary
            ? null
            : Border.all(color: AppColors.gunmetal, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.pureWhite,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.chivo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
