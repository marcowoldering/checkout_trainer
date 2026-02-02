import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // Primary training button
                          _buildPremiumButton(
                            context,
                            icon: Icons.sports,
                            label: "Start Training",
                            onPressed: () {
                              Navigator.pushNamed(context, '/trainer');
                            },
                          ),
                          const SizedBox(height: 24),
                          // Secondary buttons row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSecondaryButton(
                                  context,
                                  icon: Icons.view_list,
                                  label: "Checkouts",
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/checkouts');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSecondaryButton(
                                  context,
                                  icon: Icons.bar_chart,
                                  label: "Stats",
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/statistics');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSecondaryButton(
                                  context,
                                  icon: Icons.person,
                                  label: "Profile",
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/profile');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Support button
                    _buildSupportButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton() {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse('https://buymeacoffee.com/marcowoldering');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gunmetal),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.coffee,
              color: AppColors.amberGold,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Buy Me a Coffee',
              style: GoogleFonts.chivo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedGrey,
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
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.crimsonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimsonRed.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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

  Widget _buildSecondaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.gunmetal, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.pureWhite,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.chivo(
                  fontSize: 12,
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
