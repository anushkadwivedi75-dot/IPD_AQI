import 'dart:ui';
import 'package:airsentine1/features/ai_assistant/presentation/ai_assistant_page.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/providers/auth_provider.dart';
import 'package:airsentine1/widgets/community_alert_banner.dart';
import 'package:airsentine1/widgets/logo.dart';
import 'package:airsentine1/widgets/motion.dart';
import 'package:airsentine1/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pinned, glassmorphic header bar for AirSentinel with conditional alert banner & Theme Switcher.
class AirSentinelHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AirSentinelHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(115.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    final allStations = ref.watch(stationsListProvider);
    final alertThreshold = ref.watch(alertThresholdProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isAlertActive = station.aqi >= alertThreshold;
    final isCompact = MediaQuery.of(context).size.width < 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF141210).withValues(alpha: 0.88)
        : const Color(0xFFFAF7F2).withValues(alpha: 0.88);

    final alertsAsync = ref.watch(activeSiteAlertsProvider);
    final activeAlerts = alertsAsync.maybeWhen(data: (a) => a, orElse: () => []);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: bgColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Conditional Community / Tamper Alerts Banner
                if (activeAlerts.isNotEmpty)
                  CommunityAlertBanner(alert: activeAlerts.first),

                // 2. Conditional Alert Banner (Shown when AQI >= alertThreshold)
                if (isAlertActive) _buildConditionalAlertBar(context, station, alertThreshold),


                // 2. Main Sticky Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Redesigned Brand Logo & Wordmark
                      AirSentinelLogo(
                        layout: isCompact ? LogoLayout.compact : LogoLayout.horizontal,
                        iconSize: 34,
                        showSubtag: !isCompact,
                      ),
                      const SizedBox(width: 12),

                      // Station Selector Pill
                      Expanded(
                        child: _buildStationSelector(context, ref, station, allStations, isCompact, isDark),
                      ),
                      const SizedBox(width: 8),

                      // AQI Badge
                      _buildAqiBadge(context, station),
                      const SizedBox(width: 8),

                      // Theme Switcher Button (Sun / Moon)
                      _buildThemeSwitcher(context, ref, themeMode, isDark),
                      const SizedBox(width: 6),

                      // Offline-First Sync Status Indicator Badge
                      const SyncStatusBadge(),
                      const SizedBox(width: 6),

                      // AI Copilot CTA
                      _buildAiCopilotCta(context, isCompact),
                      const SizedBox(width: 6),

                      // User Auth Profile CTA
                      _buildUserAvatarBtn(context, ref, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Conditional Alert Bar above the header
  Widget _buildConditionalAlertBar(BuildContext context, MonitoringStation station, int alertThreshold) {
    final aqiMeta = station.aqiMeta;

    return Semantics(
      liveRegion: true,
      label: 'AirSentinel Warning: AQI for ${station.name} is ${station.aqi}, exceeding your threshold of $alertThreshold.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            const BouncingAlertIcon(
              icon: Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ALERT: ${station.name.toUpperCase()} AQI IS ${station.aqi} (${aqiMeta.label.toUpperCase()}) — EXCEEDS THRESHOLD ($alertThreshold)!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Theme Switcher Toggle (Light vs Dark)
  Widget _buildThemeSwitcher(BuildContext context, WidgetRef ref, ThemeMode themeMode, bool isDark) {
    return Semantics(
      button: true,
      label: isDark ? 'Switch to Warm Light Theme' : 'Switch to Warm Dark Theme',
      child: Tooltip(
        message: isDark ? 'Light Theme' : 'Dark Theme',
        child: InkWell(
          onTap: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF28231E) : const Color(0xFFEBE5DF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF475569),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  /// Accessible Pill-shaped Station Selector Dropdown
  Widget _buildStationSelector(
    BuildContext context,
    WidgetRef ref,
    MonitoringStation currentStation,
    List<MonitoringStation> allStations,
    bool isCompact,
    bool isDark,
  ) {
    final pillBg = isDark ? const Color(0xFF28231E) : const Color(0xFFEBE5DF);
    final pillBorder = isDark ? const Color(0xFF38322B) : const Color(0xFFDDD7CF);

    return Semantics(
      button: true,
      label: 'Select CPCB Air Quality Monitoring Station. Currently selected: ${currentStation.name} in ${currentStation.area}, AQI ${currentStation.aqi}',
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pillBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentStation.id,
            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), size: 18),
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E1B18) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            items: allStations.map((station) {
              final meta = station.aqiMeta;
              return DropdownMenuItem<String>(
                value: station.id,
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${station.name.toUpperCase()} (${station.area.toUpperCase()})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: meta.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${station.aqi}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: meta.badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newId) {
              if (newId != null) {
                ref.read(selectedStationIdProvider.notifier).setStation(newId);
              }
            },
          ),
        ),
      ),
    );
  }

  /// Colored CPCB AQI Live Badge
  Widget _buildAqiBadge(BuildContext context, MonitoringStation station) {
    final meta = station.aqiMeta;

    return Semantics(
      label: 'Live AQI Badge: ${station.aqi}, CPCB Category: ${meta.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: meta.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: meta.color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulsingDot(color: meta.dotColor, size: 8),
            const SizedBox(width: 6),
            Text(
              '${station.aqi}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: meta.badgeTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI Copilot CTA Button
  Widget _buildAiCopilotCta(BuildContext context, bool isCompact) {
    return Semantics(
      button: true,
      label: 'Open AI Health Copilot',
      child: Tooltip(
        message: 'Open AI Health Copilot',
        child: InkWell(
          onTap: () => showAiAssistantModal(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3310B981),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'COPILOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// User Profile Avatar / Login CTA
  Widget _buildUserAvatarBtn(BuildContext context, WidgetRef ref, bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Semantics(
      button: true,
      label: user != null ? 'Open Personal Dashboard for ${user.name}' : 'Sign in to AirSentinel',
      child: Tooltip(
        message: user != null ? 'Personal Dashboard (${user.name})' : 'Sign In',
        child: InkWell(
          onTap: () {
            if (user != null) {
              context.go('/personal-dashboard');
            } else {
              context.go('/login');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: user != null
                  ? const Color(0xFF007791)
                  : (isDark ? const Color(0xFF28231E) : const Color(0xFFEBE5DF)),
              shape: BoxShape.circle,
            ),
            child: user != null
                ? Center(
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_outline,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}

