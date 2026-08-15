import 'package:airsentine1/providers/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pendingCount = pendingCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final isSynced = pendingCount == 0;
    final badgeBg = isSynced
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
        : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7));

    final badgeColor = isSynced
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));

    final labelText = isSynced ? 'Synced' : '$pendingCount pending';

    return Semantics(
      button: true,
      label: 'Sync Status: $labelText. Tap to force synchronization.',
      child: Tooltip(
        message: isSynced ? 'Database synced with server' : 'Tap to sync $pendingCount pending items',
        child: InkWell(
          onTap: () {
            ref.read(syncServiceProvider).syncPendingData();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                  size: 13,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
