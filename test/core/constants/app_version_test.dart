import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/constants/app_constants.dart';

/// The app version lives in two places: pubspec.yaml, which drives
/// CFBundleShortVersionString on the store build, and
/// [AppConstants.appVersion], which is stamped onto calibration metrics.
///
/// Nothing keeps them in step at build time — Codemagic passes only
/// `--build-number`, never `--build-name` — so a release bump that touches
/// one and not the other ships a correct store version alongside telemetry
/// labelled with the previous one. That is invisible until someone reads the
/// data months later, which is what this test exists to prevent.
void main() {
  test('AppConstants.appVersion matches the version name in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    final match = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(
      match,
      isNotNull,
      reason: 'pubspec.yaml needs a version line shaped like 1.2.3+4',
    );

    expect(
      AppConstants.appVersion,
      match!.group(1),
      reason:
          'bump AppConstants.appVersion to match pubspec.yaml, or the '
          'calibration metrics will record the wrong build',
    );
  });
}
