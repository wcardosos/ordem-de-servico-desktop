import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/main.dart';

void main() {
  testWidgets(
    'shows the Portuguese database failure message without exception text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ServiceOrderApp(
          errorMessage:
              'Não foi possível acessar os dados locais do aplicativo.',
        ),
      );

      expect(
        find.text('Não foi possível acessar os dados locais do aplicativo.'),
        findsOneWidget,
      );
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('#0'), findsNothing);
      expect(find.textContaining('sqlite'), findsNothing);
    },
  );

  testWidgets(
    'starts without a failure message when the database is available',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ServiceOrderApp());

      expect(
        find.text('Não foi possível acessar os dados locais do aplicativo.'),
        findsNothing,
      );
      expect(find.text('Ordem de Serviço'), findsOneWidget);
    },
  );
}
