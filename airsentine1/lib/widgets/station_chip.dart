import 'package:flutter/material.dart';
import 'package:airsentine1/models/station.dart';

class StationChip extends StatelessWidget {
  final Station station;
  final bool selected;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const StationChip({
    super.key,
    required this.station,
    required this.selected,
    required this.favorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? station.color : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? station.background : Colors.white,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? station.color : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  station.area,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onFavoriteTap,
              borderRadius: BorderRadius.circular(14),
              child: Icon(
                favorite ? Icons.star : Icons.star_border,
                color: favorite ? const Color(0xFFECA400) : Colors.grey[500],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
