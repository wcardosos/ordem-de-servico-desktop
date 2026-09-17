import 'package:intl/intl.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);

const String _nonBreakingSpace = ' ';

String formatCurrency(double value) =>
    _currencyFormat.format(value).replaceAll(_nonBreakingSpace, ' ');
