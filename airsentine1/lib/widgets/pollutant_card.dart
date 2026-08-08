import 'package:flutter/material.dart';
import 'package:airsentine1/models/station.dart';

class PollutantCard extends StatelessWidget {
  final Pollutant pollutant;
  final VoidCallback? onTap;

  const PollutantCard({
    super.key,
    required this.pollutant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pollutant.code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${pollutant.value.toStringAsFixed(0)} ${pollutant.unit}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                pollutant.trend,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
