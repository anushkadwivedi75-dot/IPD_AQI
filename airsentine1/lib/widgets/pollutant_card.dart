import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:flutter/material.dart';

class PollutantCard extends StatelessWidget {
  final PollutantDetail pollutant;
  final VoidCallback? onTap;

  const PollutantCard({
    super.key,
    required this.pollutant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int subIndexValue = pollutant.subIndex ?? pollutant.value.round();
    final aqiMeta = getAqiMeta(subIndexValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B);

    return Semantics(
      button: onTap != null,
      label: '${pollutant.name} (${pollutant.code}): ${pollutant.value} ${pollutant.unit}, CPCB Sub-index: $subIndexValue (${aqiMeta.label})',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Code + CPCB Sub-Index Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      pollutant.code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: secondaryTextColor,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: aqiMeta.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: aqiMeta.color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'SUB-IDX: $subIndexValue',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: aqiMeta.badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Value + Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  pollutant.value < 10
                      ? pollutant.value.toStringAsFixed(1)
                      : pollutant.value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  pollutant.unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Subtitle / Trend
            Text(
              pollutant.name.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: secondaryTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
