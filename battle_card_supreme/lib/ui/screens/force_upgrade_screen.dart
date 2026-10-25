import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/aetherium_theme.dart';

class ForceUpgradeScreen extends StatelessWidget {
  const ForceUpgradeScreen({
    super.key,
    required this.currentVersion,
    required this.minVersion,
  });

  final String currentVersion;
  final String minVersion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.system_update_alt,
              size: 56,
              color: AetheriumColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'UPDATE REQUIRED',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AetheriumColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This build ($currentVersion) is below the server minimum ($minVersion). Install the latest APK before continuing online features.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AetheriumColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
