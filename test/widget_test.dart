import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alphafront/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton muestra label y responde al tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Entrar',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Entrar'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(tapped, isTrue);
  });

  testWidgets('AppButton en loading deshabilita el tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Entrar',
            loading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    expect(tapped, isFalse);
  });
}
