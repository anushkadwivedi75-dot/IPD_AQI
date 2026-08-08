import 'package:flutter/material.dart';
import 'package:airsentine1/models/station.dart';

class ForecastCard extends StatelessWidget {
  final ForecastEntry forecast;

  const ForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            forecast.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            '${forecast.aqi}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            forecast.condition,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const Spacer(),
          Text('${forecast.high}° / ${forecast.low}°', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
