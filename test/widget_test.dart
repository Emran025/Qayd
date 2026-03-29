import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/main.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

void main() {
  testWidgets('Qayd boots with Arabic title', (WidgetTester tester) async {
    await tester.pumpWidget(const QaydApp());
    expect(find.text(AppStringsAr.appTitle), findsWidgets);
  });
}
