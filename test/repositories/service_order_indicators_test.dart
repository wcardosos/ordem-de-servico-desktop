import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/service_order_filter.dart';
import 'package:ordem_de_servico/core/service_order_status.dart';
import 'package:ordem_de_servico/models/service_order_indicators.dart';
import 'package:ordem_de_servico/repositories/service_order_repository.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'service_order_test_support.dart';

void main() {
  setUpServiceOrderDatabase();

  late ServiceOrderRepository repository;

  setUp(() {
    repository = ServiceOrderRepository();
  });

  Future<Map<String, int>> seedBase() async {
    return seedIndicatorBase(await DatabaseHelper.instance.database);
  }

  Future<void> setStatus(int id, ServiceOrderStatus status) async {
    await changeStoredStatus(
      await DatabaseHelper.instance.database,
      id,
      status,
    );
  }

  test('counts every status over the verification base', () async {
    await seedBase();

    final ServiceOrderIndicators indicators = await repository
        .findIndicators();

    expect(indicators.total, 10);
    expect(indicators.open, 2);
    expect(indicators.inProgress, 2);
    expect(indicators.awaitingPart, 2);
    expect(indicators.completed, 2);
    expect(indicators.urgent, 2);
    expect(indicators.overdue, 3);
  });

  test('sums parts and labor of every order into the total amount', () async {
    await seedBase();

    final ServiceOrderIndicators indicators = await repository
        .findIndicators();

    expect(indicators.totalAmount, 2941.00);
  });

  test('keeps completed and cancelled orders out of the overdue counter', () async {
    final Map<String, int> identifiers = await seedBase();
    expect((await repository.findIndicators()).overdue, 3);

    await setStatus(identifiers['OS-2026-0008']!, ServiceOrderStatus.open);
    expect((await repository.findIndicators()).overdue, 4);

    await setStatus(identifiers['OS-2026-0009']!, ServiceOrderStatus.open);
    expect((await repository.findIndicators()).overdue, 5);

    await setStatus(identifiers['OS-2026-0010']!, ServiceOrderStatus.open);
    expect((await repository.findIndicators()).overdue, 6);
  });

  test('counts the past due orders that are still under attendance', () async {
    final Map<String, int> identifiers = await seedBase();
    expect((await repository.findIndicators()).overdue, 3);

    await setStatus(
      identifiers['OS-2026-0002']!,
      ServiceOrderStatus.completed,
    );
    expect((await repository.findIndicators()).overdue, 2);

    await setStatus(
      identifiers['OS-2026-0005']!,
      ServiceOrderStatus.completed,
    );
    expect((await repository.findIndicators()).overdue, 1);

    await setStatus(
      identifiers['OS-2026-0007']!,
      ServiceOrderStatus.completed,
    );
    expect((await repository.findIndicators()).overdue, 0);
  });

  test('an order due today is not overdue', () async {
    final Database database = await DatabaseHelper.instance.database;
    await seedIndicatorBase(database);
    final DateTime now = DateTime.now();
    await database.update(
      'service_orders',
      <String, Object?>{
        'due_date':
            '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}',
      },
      where: 'number = ?',
      whereArgs: <Object?>['OS-2026-0002'],
    );

    expect((await repository.findIndicators()).overdue, 2);
  });

  test('reports zeros for a database without service orders', () async {
    final ServiceOrderIndicators indicators = await repository
        .findIndicators();

    expect(indicators.total, 0);
    expect(indicators.open, 0);
    expect(indicators.inProgress, 0);
    expect(indicators.awaitingPart, 0);
    expect(indicators.completed, 0);
    expect(indicators.urgent, 0);
    expect(indicators.overdue, 0);
    expect(indicators.totalAmount, 0);
  });

  test('the awaiting part counter matches the filtered list', () async {
    await seedBase();

    final ServiceOrderIndicators indicators = await repository
        .findIndicators();

    expect(
      indicators.awaitingPart,
      (await repository.findFiltered(
        const ServiceOrderFilter(status: ServiceOrderStatus.awaitingPart),
      )).length,
    );
  });
}
