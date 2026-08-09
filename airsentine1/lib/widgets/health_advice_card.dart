import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:flutter/material.dart';

class HealthAdviceCard extends StatelessWidget {
  final HealthAdvice advice;

  const HealthAdviceCard({
    super.key,
    required this.advice,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: 'Health recommendation: ${advice.title}. ${advice.description}',
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: advice.tint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(advice.icon, color: advice.tint, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advice.title.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
