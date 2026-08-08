import 'package:flutter/material.dart';
import 'package:airsentine1/models/station.dart';

class HealthAdviceCard extends StatelessWidget {
  final HealthAdvice advice;

  const HealthAdviceCard({
    super.key,
    required this.advice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: advice.tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(advice.icon, color: advice.tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(advice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(advice.description, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
