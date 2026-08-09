import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:airsentine1/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Interactive Station Quick List with scale-up animation for selected station and Hardware Info action
class StationQuickList extends ConsumerWidget {
  const StationQuickList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStations = ref.watch(stationsListProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final favorites = ref.watch(favoriteStationIdsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allStations.length,
        itemBuilder: (context, index) {
          final station = allStations[index];
          final isSelected = station.id == selectedStation.id;
          final isFavorite = favorites.contains(station.id);
          final meta = station.aqiMeta;

          final cardBg = isSelected
              ? meta.backgroundColor
              : (isDark ? const Color(0xFF1E1B18) : Colors.white);

          final titleColor = isSelected
              ? meta.badgeTextColor
              : (isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A));

          final subtitleColor = isSelected
              ? meta.badgeTextColor.withValues(alpha: 0.8)
              : (isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B));

          final linkColor = isSelected
              ? meta.badgeTextColor
              : (isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58));

          return Padding(
            padding: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
            child: AnimatedScale(
              scale: isSelected ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Station ${station.name} in ${station.area}. AQI ${station.aqi}, CPCB Category ${meta.label}.${isFavorite ? " Favorite station." : ""}',
                child: AppCard(
                  onTap: () {
                    ref.read(selectedStationIdProvider.notifier).setStation(station.id);
                  },
                  backgroundColor: cardBg,
                  border: Border.all(
                    color: isSelected ? meta.color : (isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 210,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header Row: Station Name + Favorite Button
                        Row(
                          children: [
                            if (isSelected) ...[
                              PulsingDot(color: meta.dotColor, size: 8),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                station.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                  color: titleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: 'Toggle Favorite for ${station.name}',
                              child: InkWell(
                                onTap: () {
                                  ref.read(favoriteStationIdsProvider.notifier).toggleFavorite(station.id);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    isFavorite ? Icons.star : Icons.star_border,
                                    color: isFavorite ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Text(
                          station.area.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: subtitleColor,
                          ),
                        ),

                        // AQI Badge & Hardware Info Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: meta.color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${station.aqi}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    meta.label.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Hardware Info Action Button
                            Semantics(
                              button: true,
                              label: 'Hardware Info for ${station.name}',
                              child: InkWell(
                                onTap: () => context.push('/station/${station.id}'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        'HARDWARE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                          color: linkColor,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: linkColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
