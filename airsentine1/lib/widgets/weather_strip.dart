import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:flutter/material.dart';

/// 4-card Weather Strip displaying Temperature (°C), Humidity (%), Wind (km/h), and UV Index
class WeatherStrip extends StatelessWidget {
  final WeatherInfo weather;

  const WeatherStrip({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 36) / 4;
        final bool isSmallScreen = constraints.maxWidth < 600;

        if (isSmallScreen) {
          return GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            children: [
              _buildWeatherCard(
                context,
                icon: Icons.thermostat_outlined,
                iconColor: const Color(0xFFEF4444),
                value: '${weather.temperatureC}°C',
                label: 'TEMPERATURE',
                semanticsLabel: 'Temperature ${weather.temperatureC} degrees Celsius',
                isDark: isDark,
              ),
              _buildWeatherCard(
                context,
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF3B82F6),
                value: '${weather.humidity}%',
                label: 'HUMIDITY',
                semanticsLabel: 'Humidity ${weather.humidity} percent',
                isDark: isDark,
              ),
              _buildWeatherCard(
                context,
                icon: Icons.air,
                iconColor: const Color(0xFF10B981),
                value: '${weather.windKph} km/h',
                label: 'WIND SPEED',
                semanticsLabel: 'Wind speed ${weather.windKph} kilometers per hour',
                isDark: isDark,
              ),
              _buildWeatherCard(
                context,
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFF59E0B),
                value: 'UV ${weather.uvIndex}',
                label: 'UV INDEX',
                semanticsLabel: 'UV Index ${weather.uvIndex}',
                isDark: isDark,
              ),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildWeatherCard(
                context,
                icon: Icons.thermostat_outlined,
                iconColor: const Color(0xFFEF4444),
                value: '${weather.temperatureC}°C',
                label: 'TEMPERATURE',
                semanticsLabel: 'Temperature ${weather.temperatureC} degrees Celsius',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: cardWidth,
              child: _buildWeatherCard(
                context,
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF3B82F6),
                value: '${weather.humidity}%',
                label: 'HUMIDITY',
                semanticsLabel: 'Humidity ${weather.humidity} percent',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: cardWidth,
              child: _buildWeatherCard(
                context,
                icon: Icons.air,
                iconColor: const Color(0xFF10B981),
                value: '${weather.windKph} km/h',
                label: 'WIND SPEED',
                semanticsLabel: 'Wind speed ${weather.windKph} kilometers per hour',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: cardWidth,
              child: _buildWeatherCard(
                context,
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFF59E0B),
                value: 'UV ${weather.uvIndex}',
                label: 'UV INDEX',
                semanticsLabel: 'UV Index ${weather.uvIndex}',
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String semanticsLabel,
    required bool isDark,
  }) {
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B);

    return Semantics(
      label: semanticsLabel,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: primaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
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
          ],
        ),
      ),
    );
  }
}
