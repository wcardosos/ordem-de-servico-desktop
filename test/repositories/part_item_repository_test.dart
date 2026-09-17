import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/models/part_item.dart';
import 'package:ordem_de_servico/models/service_order.dart';
import 'package:ordem_de_servico/repositories/part_item_repository.dart';
import 'package:ordem_de_servico/repositories/service_order_repository.dart';
import 'package:ordem_de_servico/services/database_helper.dart';

import 'service_order_test_support.dart';

PartItem compressor(int serviceOrderId) => PartItem(
  serviceOrderId: serviceOrderId,
  description: 'Compressor 1/3 HP',
  quantity: 1,
  unitPrice: 780.00,
);

PartItem refrigerantGas(int serviceOrderId) => PartItem(
  serviceOrderId: serviceOrderId,
  description: 'Gás refrigerante R410A',
  quantity: 2,
  unitPrice: 95.50,
);

void main() {
  setUpServiceOrderDatabase();

  late PartItemRepository repository;
  late ServiceOrderRepository orderRepository;

  setUp(() {
    repository = PartItemRepository();
    orderRepository = ServiceOrderRepository();
  });

  Future<ServiceOrder> orderWithStoredItems(
    int orderId, {
    double laborCost = 0,
  }) async {
    return newOrder(
      laborCost: laborCost,
      partItems: await repository.findByServiceOrder(orderId),
    );
  }

  test(
    'stores the part items of an order and reads them back with subtotals',
    () async {
      final int orderId = await orderRepository.insert(newOrder());

      await repository.insert(compressor(orderId));
      await repository.insert(refrigerantGas(orderId));

      final List<PartItem> items = await repository.findByServiceOrder(orderId);
      expect(items, hasLength(2));
      expect(items.first.description, 'Compressor 1/3 HP');
      expect(items.first.quantity, 1);
      expect(items.first.unitPrice, 780.00);
      expect(items.first.subtotal, 780.00);
      expect(items.last.description, 'Gás refrigerante R410A');
      expect(items.last.quantity, 2);
      expect(items.last.unitPrice, 95.50);
      expect(items.last.subtotal, 191.00);
    },
  );

  test('reads back only the part items of the requested order', () async {
    final int first = await orderRepository.insert(newOrder());
    final int second = await orderRepository.insert(newOrder());
    await repository.insert(compressor(first));
    await repository.insert(refrigerantGas(second));

    expect(await repository.findByServiceOrder(first), hasLength(1));
    expect(
      (await repository.findByServiceOrder(second)).single.description,
      'Gás refrigerante R410A',
    );
  });

  test('inserts nothing when the part item cannot be stored', () async {
    await expectLater(
      repository.insert(compressor(999)),
      throwsA(isA<DatabaseAccessException>()),
    );

    expect(await repository.findByServiceOrder(999), isEmpty);
  });

  test('recomputes the order total after a part item is removed', () async {
    final int orderId = await orderRepository.insert(
      newOrder(laborCost: 150.00),
    );
    await repository.insert(compressor(orderId));
    final int gasId = await repository.insert(refrigerantGas(orderId));
    final ServiceOrder before = await orderWithStoredItems(
      orderId,
      laborCost: 150.00,
    );
    expect(before.totalAmount, 1121.00);

    await repository.delete(gasId);

    final ServiceOrder after = await orderWithStoredItems(
      orderId,
      laborCost: 150.00,
    );
    expect(after.partsTotal, 780.00);
    expect(after.totalAmount, 930.00);
  });

  test('removes every part item of a single order', () async {
    final int kept = await orderRepository.insert(newOrder());
    final int removed = await orderRepository.insert(newOrder());
    await repository.insert(compressor(kept));
    await repository.insert(compressor(removed));
    await repository.insert(refrigerantGas(removed));

    await repository.deleteByServiceOrder(removed);

    expect(await repository.findByServiceOrder(removed), isEmpty);
    expect(await repository.findByServiceOrder(kept), hasLength(1));
  });

  test('sums the subtotals of the part items of every order', () async {
    final int first = await orderRepository.insert(newOrder());
    final int second = await orderRepository.insert(newOrder());
    await repository.insert(compressor(first));
    await repository.insert(refrigerantGas(second));

    expect(await repository.sumAllOrders(), 971.00);
  });

  test('sums zero when no order has part items', () async {
    expect(await repository.sumAllOrders(), 0);
  });

  test('lists orders with empty part item collections', () async {
    final List<int> orderIds = <int>[];
    for (int i = 0; i < 10; i++) {
      orderIds.add(await orderRepository.insert(newOrder()));
    }
    for (final int orderId in orderIds.take(4)) {
      await repository.insert(compressor(orderId));
    }

    final List<ServiceOrder> orders = await orderRepository.findAll();

    expect(orders, hasLength(10));
    for (final ServiceOrder order in orders) {
      expect(order.partItems, isEmpty);
      expect(identical(order.partItems, const <PartItem>[]), isTrue);
      expect(order.partsTotal, 0);
    }
  });
}
