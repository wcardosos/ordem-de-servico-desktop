import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/widgets/app_snack_bar.dart';

void main() {
  Future<ColorScheme> pumpTrigger(
    WidgetTester tester,
    String message,
    SnackBarKind kind,
  ) async {
    late ColorScheme colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              colors = Theme.of(context).colorScheme;
              return TextButton(
                onPressed: () => showAppSnackBar(context, message, kind: kind),
                child: const Text('Mostrar'),
              );
            },
          ),
        ),
      ),
    );
    return colors;
  }

  Future<void> trigger(WidgetTester tester) async {
    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();
  }

  const Map<SnackBarKind, IconData> expectedIcons = <SnackBarKind, IconData>{
    SnackBarKind.success: Icons.check_circle_outline,
    SnackBarKind.warning: Icons.warning_amber_rounded,
    SnackBarKind.error: Icons.error_outline,
  };

  for (final SnackBarKind kind in SnackBarKind.values) {
    testWidgets('shows a ${kind.name} snackbar with its color and icon', (
      WidgetTester tester,
    ) async {
      final ColorScheme colors = await pumpTrigger(tester, 'Mensagem', kind);

      await trigger(tester);

      final SnackBar snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, snackBarColor(kind, colors));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Mensagem'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(expectedIcons[kind]!),
        ),
        findsOneWidget,
      );
    });
  }

  test('uses distinct colors and the theme error color for errors', () {
    final ColorScheme colors = ColorScheme.fromSeed(seedColor: Colors.indigo);

    expect(snackBarColor(SnackBarKind.error, colors), colors.error);
    expect(<Color>{
      for (final SnackBarKind kind in SnackBarKind.values)
        snackBarColor(kind, colors),
    }, hasLength(SnackBarKind.values.length));
  });

  testWidgets('replaces the snackbar already showing', (
    WidgetTester tester,
  ) async {
    await pumpTrigger(tester, 'Primeira', SnackBarKind.success);
    await trigger(tester);
    expect(find.text('Primeira'), findsOneWidget);

    await pumpTrigger(tester, 'Segunda', SnackBarKind.error);
    await trigger(tester);

    expect(find.text('Primeira'), findsNothing);
    expect(find.text('Segunda'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
