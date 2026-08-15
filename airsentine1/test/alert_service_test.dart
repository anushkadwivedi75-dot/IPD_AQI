import 'package:airsentine1/models/alert.dart';
import 'package:airsentine1/widgets/community_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAlert Model & CommunityAlertBanner Tests', () {
    test('AppAlert.fromJson and toJson round-trip', () {
      final jsonMap = {
        'id': 'test-alert-123',
        'site_id': 'site-abc',
        'type': 'divergence',
        'severity': 2,
        'evidence': {
          'official_aqi': 150,
          'community_median_aqi': 50,
          'divergence': 100,
        },
      };

      final alert = AppAlert.fromJson(jsonMap);
      expect(alert.id, equals('test-alert-123'));
      expect(alert.siteId, equals('site-abc'));
      expect(alert.type, equals('divergence'));
      expect(alert.severity, equals(2));
      expect(alert.evidence?['official_aqi'], equals(150));

      final serialized = alert.toJson();
      expect(serialized['id'], equals('test-alert-123'));
      expect(serialized['type'], equals('divergence'));
    });

    testWidgets('CommunityAlertBanner renders divergence alert correctly', (WidgetTester tester) async {
      final alert = AppAlert(
        id: 'a1',
        siteId: 's1',
        type: 'divergence',
        severity: 2,
        evidence: {
          'official_aqi': 180,
          'community_median_aqi': 70,
          'divergence': 110,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityAlertBanner(alert: alert),
          ),
        ),
      );

      expect(find.text('Receive Community Alert: AQI Divergence'), findsOneWidget);
      expect(find.textContaining('Official AQI: 180'), findsOneWidget);
      expect(find.textContaining('Community Median AQI: 70'), findsOneWidget);
    });

    testWidgets('CommunityAlertBanner renders anomaly alert correctly', (WidgetTester tester) async {
      final alert = AppAlert(
        id: 'a2',
        siteId: 's2',
        type: 'anomaly',
        severity: 3,
        evidence: {
          'anomaly_score': -0.15,
          'aqi': 350,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityAlertBanner(alert: alert),
          ),
        ),
      );

      expect(find.text('Receive Community Alert: Anomaly Detected'), findsOneWidget);
      expect(find.textContaining('IsolationForest score: -0.15'), findsOneWidget);
    });
  });
}
