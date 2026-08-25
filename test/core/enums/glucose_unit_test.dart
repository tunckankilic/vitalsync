// Unit tests for the glucose display unit.
//
// The storage contract is that a reading is always persisted in mg/dL, so
// the conversion in both directions is what these tests pin down.

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/glucose_unit.dart';

void main() {
  group('GlucoseUnit.mgPerDl', () {
    test('is the storage unit and converts to itself unchanged', () {
      expect(GlucoseUnit.mgPerDl.toMgDl(100), 100);
      expect(GlucoseUnit.mgPerDl.fromMgDl(100), 100);
    });

    test('formats without decimals', () {
      expect(GlucoseUnit.mgPerDl.formatMgDl(99.6), '100');
      expect(GlucoseUnit.mgPerDl.formatMgDlWithLabel(100), '100 mg/dL');
    });
  });

  group('GlucoseUnit.mmolPerL', () {
    test('converts an entered value into mg/dL for storage', () {
      // 5.5 mmol/L is the common worked example: ~99.1 mg/dL.
      expect(GlucoseUnit.mmolPerL.toMgDl(5.5), closeTo(99.1, 0.1));
    });

    test('converts a stored mg/dL value for display', () {
      expect(GlucoseUnit.mmolPerL.fromMgDl(100), closeTo(5.55, 0.01));
    });

    test('round-trips a value back to itself', () {
      const entered = 7.2;
      final stored = GlucoseUnit.mmolPerL.toMgDl(entered);
      expect(GlucoseUnit.mmolPerL.fromMgDl(stored), closeTo(entered, 0.0001));
    });

    test('formats with one decimal', () {
      // 100 mg/dL is 5.549 mmol/L, which rounds down at one decimal.
      expect(GlucoseUnit.mmolPerL.formatMgDl(100), '5.5');
      expect(GlucoseUnit.mmolPerL.formatMgDlWithLabel(100), '5.5 mmol/L');
    });
  });
}
