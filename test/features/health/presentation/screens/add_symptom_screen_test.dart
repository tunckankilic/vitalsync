import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/features/health/presentation/screens/add_symptom_screen.dart';

import '../../../../support/pump_app.dart';

/// The quick-pick chips do more than label something: tapping one writes its
/// text into the name field, and that text is what gets stored as the symptom.
/// So a chip showing English in a Turkish build does not just look wrong, it
/// puts English into the user's own data.
///
/// A missing .arb key would produce exactly that and would not fail the build —
/// gen-l10n falls back to the English template instead.
void main() {
  Future<void> pumpIn(WidgetTester tester, String languageCode) async {
    await pumpScreen(
      tester,
      const AddSymptomScreen(),
      locale: Locale(languageCode),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers the quick-pick symptoms in Turkish', (tester) async {
    await pumpIn(tester, 'tr');

    expect(find.widgetWithText(ActionChip, 'Baş Ağrısı'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Mide Bulantısı'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Headache'), findsNothing);
  });

  testWidgets('offers the quick-pick symptoms in German', (tester) async {
    await pumpIn(tester, 'de');

    expect(find.widgetWithText(ActionChip, 'Kopfschmerzen'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Übelkeit'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Headache'), findsNothing);
  });

  testWidgets('tapping a chip fills the name field with that language', (
    tester,
  ) async {
    await pumpIn(tester, 'tr');

    await tester.tap(find.widgetWithText(ActionChip, 'Baş Ağrısı'));
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(field.controller?.text, 'Baş Ağrısı');
  });
}
