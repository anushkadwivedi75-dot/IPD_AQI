import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:flutter/material.dart';

class ForecastCard extends StatelessWidget {
  final DailyForecast forecast;

  const ForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    final meta = getAqiMeta(forecast.aqi);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B);

    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),
      child: Semantics(
        label: 'Forecast for ${forecast.label}: AQI ${forecast.aqi}, CPCB Category ${meta.label}, ${forecast.condition}, High ${forecast.high}°C Low ${forecast.low}°C',
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    forecast.label.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${forecast.aqi}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryTextColor),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: meta.backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            meta.label.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: meta.badgeTextColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    forecast.condition,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Text(
                '${forecast.high}° / ${forecast.low}°C',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
