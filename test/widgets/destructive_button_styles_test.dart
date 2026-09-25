import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/widgets/destructive_button_styles.dart';

void main() {
  const Key iconKey = Key('icon');
  const Key outlinedKey = Key('outlined');
  const Key disabledOutlinedKey = Key('disabled-outlined');
  const Key filledKey = Key('filled');
  const Set<WidgetState> enabled = <WidgetState>{};
  const Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};

  Future<ColorScheme> pumpButtons(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              final ColorScheme colors = Theme.of(context).colorScheme;
              return Column(
                children: <Widget>[
                  IconButton(
                    key: iconKey,
                    style: destructiveIconButtonStyle(colors),
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline),
                  ),
                  OutlinedButton(
                    key: outlinedKey,
                    style: destructiveOutlinedButtonStyle(colors),
                    onPressed: () {},
                    child: const Text('Excluir'),
                  ),
                  OutlinedButton(
                    key: disabledOutlinedKey,
                    style: destructiveOutlinedButtonStyle(colors),
                    onPressed: null,
                    child: const Text('Remover imagem'),
                  ),
                  FilledButton(
                    key: filledKey,
                    style: destructiveFilledButtonStyle(colors),
                    onPressed: () {},
                    child: const Text('Excluir'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    return Theme.of(tester.element(find.byKey(iconKey))).colorScheme;
  }

  ButtonStyle styleOf(WidgetTester tester, Key key) {
    final Widget button = tester.widget(find.byKey(key));
    if (button is IconButton) {
      return button.style!;
    }
    return (button as ButtonStyleButton).style!;
  }

  testWidgets('icon button uses the error color when enabled', (
    WidgetTester tester,
  ) async {
    final ColorScheme colors = await pumpButtons(tester);

    expect(
      styleOf(tester, iconKey).foregroundColor?.resolve(enabled),
      colors.error,
    );
  });

  testWidgets('outlined button uses the error color for text and border', (
    WidgetTester tester,
  ) async {
    final ColorScheme colors = await pumpButtons(tester);
    final ButtonStyle style = styleOf(tester, outlinedKey);

    expect(style.foregroundColor?.resolve(enabled), colors.error);
    expect(style.side?.resolve(enabled)?.color, colors.error);
  });

  testWidgets('disabled outlined button does not keep the error border', (
    WidgetTester tester,
  ) async {
    final ColorScheme colors = await pumpButtons(tester);
    final ButtonStyle style = styleOf(tester, disabledOutlinedKey);

    expect(style.side?.resolve(disabled)?.color, isNot(colors.error));
    expect(style.foregroundColor?.resolve(disabled), isNot(colors.error));
  });

  testWidgets('filled button uses the error background and onError text', (
    WidgetTester tester,
  ) async {
    final ColorScheme colors = await pumpButtons(tester);
    final ButtonStyle style = styleOf(tester, filledKey);

    expect(style.backgroundColor?.resolve(enabled), colors.error);
    expect(style.foregroundColor?.resolve(enabled), colors.onError);
  });
}
