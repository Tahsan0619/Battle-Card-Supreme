import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/aetherium_theme.dart';

class VitalBar extends StatelessWidget {
  const VitalBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.shield = 0,
  });

  final String label;
  final int value;
  final int max;
  final Color color;
  final int shield;

  @override
  Widget build(BuildContext context) {
    final pct = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final shieldPct = max <= 0 ? 0.0 : (shield / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AetheriumColors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              shield > 0 ? '$value +$shield / $max' : '$value / $max',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AetheriumColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AetheriumColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (shield > 0)
                FractionallySizedBox(
                  widthFactor: (pct + shieldPct).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AetheriumColors.shield.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
