import 'package:airsentine1/core/aqi_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CPCB AQI Scale & getAqiMeta() Tests', () {
    test('AQI 0-50 should return Good category and green color', () {
      final meta = getAqiMeta(35);
      expect(meta.category, equals(CpcbAqiCategory.good));
      expect(meta.label, equals('Good'));
      expect(meta.gaugePercent, equals((35 / 500) * 100));
    });

    test('AQI 51-100 should return Satisfactory category', () {
      final meta = getAqiMeta(75);
      expect(meta.category, equals(CpcbAqiCategory.satisfactory));
      expect(meta.label, equals('Satisfactory'));
    });

    test('AQI 101-200 should return Moderate category', () {
      final meta = getAqiMeta(145);
      expect(meta.category, equals(CpcbAqiCategory.moderate));
      expect(meta.label, equals('Moderate'));
    });

    test('AQI 201-300 should return Poor category', () {
      final meta = getAqiMeta(245);
      expect(meta.category, equals(CpcbAqiCategory.poor));
      expect(meta.label, equals('Poor'));
    });

    test('AQI 301-400 should return Very Poor category', () {
      final meta = getAqiMeta(330);
      expect(meta.category, equals(CpcbAqiCategory.veryPoor));
      expect(meta.label, equals('Very Poor'));
    });

    test('AQI 401-500 should return Severe category', () {
      final meta = getAqiMeta(412);
      expect(meta.category, equals(CpcbAqiCategory.severe));
      expect(meta.label, equals('Severe'));
      expect(meta.gaugePercent, equals((412 / 500) * 100));
    });

    test('AQI > 500 should cap gaugePercent at 100 and return Severe', () {
      final meta = getAqiMeta(550);
      expect(meta.category, equals(CpcbAqiCategory.severe));
      expect(meta.gaugePercent, equals(100.0));
    });
  });
}
