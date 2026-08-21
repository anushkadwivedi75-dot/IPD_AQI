import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:airsentine1/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State provider for active health profile selection
final selectedHealthProfileProvider = StateProvider<String>((ref) => 'General');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertThreshold = ref.watch(alertThresholdProvider);
    final notificationsEnabled = ref.watch(notificationEnabledProvider);
    final useMetric = ref.watch(unitPreferenceProvider);
    final allStations = ref.watch(stationsListProvider);
    final favoriteIds = ref.watch(favoriteStationIdsProvider);
    final selectedHealthProfile = ref.watch(selectedHealthProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS & PREFERENCES'),
        actions: [
          // Header Save Action Button
          Semantics(
            button: true,
            label: 'Save Settings and Preferences',
            child: TextButton.icon(
              onPressed: () {
                // =========================================================================
                // REAL BACKEND PERSISTENCE NOTE:
                // Currently updates local app state via Riverpod & SharedPreferences.
                // Wire to FastAPI backend endpoint POST /api/v1/user/preferences or
                // persistent SQLite/Hive database store here.
                // =========================================================================
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings & Preferences saved successfully!'),
                    backgroundColor: Color(0xFF0F9D58),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.check, color: Color(0xFF0F9D58)),
              label: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F9D58), letterSpacing: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 0. Theme Mode Card (Warm Light vs Warm Dark)
            const SectionTitle(title: 'App Theme Mode', icon: Icons.palette_outlined),
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: _buildThemeModePill(
                      context,
                      ref,
                      title: 'WARM LIGHT',
                      icon: Icons.light_mode,
                      isSelected: themeMode == ThemeMode.light,
                      targetMode: ThemeMode.light,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeModePill(
                      context,
                      ref,
                      title: 'WARM DARK',
                      icon: Icons.dark_mode,
                      isSelected: themeMode == ThemeMode.dark,
                      targetMode: ThemeMode.dark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. CPCB Alert Preferences Section
            const SectionTitle(title: 'Alert Preferences', icon: Icons.tune),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('REAL-TIME NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                    subtitle: const Text('Receive real-time CPCB AQI alert push notifications'),
                    value: notificationsEnabled,
                    activeTrackColor: const Color(0xFF0F9D58),
                    onChanged: (value) => ref.read(notificationEnabledProvider.notifier).setEnabled(value),
                  ),
                  const Divider(),

                  // CPCB Alert Threshold Slider with live numeric value and breakpoints
                  ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CPCB ALERT THRESHOLD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: getAqiMeta(alertThreshold).backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: getAqiMeta(alertThreshold).color),
                          ),
                          child: Text(
                            '$alertThreshold • ${getAqiMeta(alertThreshold).label.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: getAqiMeta(alertThreshold).badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text('Slider breakpoints at CPCB intervals (50, 100, 200, 300, 400)'),
                  ),
                  Semantics(
                    label: 'CPCB AQI Alert Threshold Slider. Current value is $alertThreshold out of 500 (${getAqiMeta(alertThreshold).label})',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Slider(
                            min: 50,
                            max: 400,
                            divisions: 35,
                            activeColor: getAqiMeta(alertThreshold).color,
                            label: '$alertThreshold',
                            value: alertThreshold.toDouble().clamp(50, 400),
                            onChanged: (value) => ref.read(alertThresholdProvider.notifier).setThreshold(value.round()),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('50 GOOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00B050))),
                                SizedBox(width: 8),
                                Text('100 SAT.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7CB342))),
                                SizedBox(width: 8),
                                Text('200 MOD.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFBC02D))),
                                SizedBox(width: 8),
                                Text('300 POOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
                                SizedBox(width: 8),
                                Text('400 SEVERE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF70131B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),

                  SwitchListTile(
                    title: const Text('METRIC MEASUREMENT UNITS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                    subtitle: const Text('Use standard Indian CPCB metric measurement units (°C, km/h, µg/m³)'),
                    value: useMetric,
                    activeTrackColor: const Color(0xFF0F9D58),
                    onChanged: (_) => ref.read(unitPreferenceProvider.notifier).toggleUnits(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Health Profile Selection Grid
            const SectionTitle(title: 'Personalized Health Profile', icon: Icons.person_outline),
            const SizedBox(height: 14),
            _buildHealthProfileGrid(context, ref, selectedHealthProfile, isDark),
            const SizedBox(height: 24),

            // 3. Favorite CPCB Station Management
            const SectionTitle(title: 'Favorite CPCB Stations', icon: Icons.star_border),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAP STAR ICONS TO TOGGLE FAVORITE CPCB STATIONS:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allStations.map((station) {
                      final isFav = favoriteIds.contains(station.id);
                      final meta = station.aqiMeta;

                      return Semantics(
                        button: true,
                        selected: isFav,
                        label: '${station.name} (${station.area}), AQI ${station.aqi}. ${isFav ? "Favorited" : "Not favorited"}. Tap to toggle.',
                        child: InkWell(
                          onTap: () {
                            ref.read(favoriteStationIdsProvider.notifier).toggleFavorite(station.id);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isFav ? meta.backgroundColor : (isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isFav ? meta.color : (isDark ? const Color(0xFF38322B) : const Color(0xFFCBD5E1)),
                                width: isFav ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFav ? Icons.star : Icons.star_border,
                                  color: isFav ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${station.name.toUpperCase()} (${station.aqi})',
                                  style: TextStyle(
                                    fontWeight: isFav ? FontWeight.bold : FontWeight.w600,
                                    color: isFav ? meta.badgeTextColor : (isDark ? const Color(0xFFF5F2EB) : const Color(0xFF334155)),
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Theme Mode Pill Selector
  Widget _buildThemeModePill(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required ThemeMode targetMode,
  }) {
    final activeColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select $title theme mode',
      child: InkWell(
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(targetMode);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFCBD5E1),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? activeColor : const Color(0xFF64748B), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Health Profile Grid Selection Widget
  Widget _buildHealthProfileGrid(BuildContext context, WidgetRef ref, String selectedProfile, bool isDark) {
    final profiles = [
      {'id': 'General', 'title': 'General Public', 'icon': Icons.groups_outlined, 'desc': 'Standard CPCB advisory'},
      {'id': 'Child', 'title': 'Children & Toddlers', 'icon': Icons.child_care_outlined, 'desc': 'Extra sensitive to PM2.5'},
      {'id': 'Elderly', 'title': 'Senior Citizens', 'icon': Icons.elderly_outlined, 'desc': 'Cardiovascular precautions'},
      {'id': 'Respiratory', 'title': 'Asthma / Respiratory', 'icon': Icons.air_outlined, 'desc': 'Inhaler & mask alerts'},
      {'id': 'Pregnant', 'title': 'Expectant Mothers', 'icon': Icons.pregnant_woman_outlined, 'desc': 'Maternal health focus'},
      {'id': 'Outdoor Worker', 'title': 'Outdoor Worker', 'icon': Icons.construction_outlined, 'desc': 'High exposure guidance'},
    ];

    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: profiles.map((p) {
        final id = p['id'] as String;
        final title = p['title'] as String;
        final icon = p['icon'] as IconData;
        final desc = p['desc'] as String;
        final isSelected = selectedProfile == id;

        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Health Profile $title: $desc. ${isSelected ? "Currently selected" : "Tap to select"}',
          child: AppCard(
            onTap: () {
              ref.read(selectedHealthProfileProvider.notifier).state = id;
            },
            backgroundColor: isSelected
                ? (isDark ? const Color(0xFF1E3A2B) : const Color(0xFFE8F5E9))
                : (isDark ? const Color(0xFF1E1B18) : Colors.white),
            border: Border.all(
              color: isSelected ? primaryColor : (isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.0 : 1.0,
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                                color: isSelected ? primaryColor : (isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: primaryColor, size: 14),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
