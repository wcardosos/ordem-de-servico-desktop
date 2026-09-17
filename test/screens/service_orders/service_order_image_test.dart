import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/controllers/service_order_controller.dart';
import 'package:ordem_de_servico/screens/service_orders/service_order_detail_view.dart';
import 'package:ordem_de_servico/screens/service_orders/service_orders_module.dart';
import 'package:ordem_de_servico/services/database_helper.dart';
import 'package:ordem_de_servico/services/image_service.dart';
import 'package:path/path.dart' as p;

import 'service_orders_test_support.dart';

void main() {
  final TemporaryDatabase temporaryDatabase = TemporaryDatabase()
    ..register('ordem_servico_order_image_test_');

  late Directory sourceDirectory;

  setUp(() {
    ImageService.baseDirectoryOverride = temporaryDatabase.directory.path;
    sourceDirectory = Directory(
      p.join(temporaryDatabase.directory.path, 'origem'),
    )..createSync(recursive: true);
  });

  tearDown(() {
    ImageService.baseDirectoryOverride = null;
  });

  String storedImagePath(String fileName) => p.join(
    temporaryDatabase.directory.path,
    ImageService.imagesDirectoryName,
    fileName,
  );

  String writeSourceFile(String fileName, String content) {
    final File file = File(p.join(sourceDirectory.path, fileName))
      ..writeAsStringSync(content);
    return file.path;
  }

  List<String> imagesDirectoryFileNames() {
    final Directory directory = Directory(
      p.join(temporaryDatabase.directory.path, ImageService.imagesDirectoryName),
    );
    if (!directory.existsSync()) {
      return <String>[];
    }
    return directory
        .listSync()
        .map((FileSystemEntity entity) => p.basename(entity.path))
        .toList()
      ..sort();
  }

  Future<void> seedOrder(
    WidgetTester tester, {
    String number = 'OS-2026-0001',
    String status = 'inProgress',
    String? imagePath,
  }) async {
    await withDatabase(tester, (database) async {
      await clearServiceOrderData(database);
      final int customerId = await insertCustomer(
        database,
        name: 'Ana Ribeiro',
        document: '11122233344',
      );
      final int equipmentId = await insertEquipmentFor(
        database,
        customerId: customerId,
        type: 'Ar-condicionado split',
      );
      await insertServiceOrder(
        database,
        number: number,
        customerId: customerId,
        equipmentId: equipmentId,
        status: status,
        diagnosis: 'Compressor com falha de partida',
        solution: 'Compressor substituído',
        imagePath: imagePath,
      );
    });
  }

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 30; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    await tester.pump();
    await settle(tester);
  }

  Future<void> revealAndTap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pump();
    await tapAndSettle(tester, target);
  }

  Future<void> openDetail(WidgetTester tester, String number) async {
    await tapAndSettle(tester, find.text(number));
  }

  Future<void> tapAttach(WidgetTester tester) async {
    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.attachImageButtonKey),
    );
  }

  Finder inSnackBar(String text) {
    return find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text),
    );
  }

  Finder imageInDetail() {
    return find.descendant(
      of: find.byKey(ServiceOrderDetailView.imageSlotKey),
      matching: find.byType(Image),
    );
  }

  String? displayedImagePath(WidgetTester tester) {
    final Finder finder = imageInDetail();
    if (finder.evaluate().isEmpty) {
      return null;
    }
    final Image image = tester.widget<Image>(finder.first);
    return (image.image as FileImage).file.path;
  }

  Future<Object?> storedImagePathOf(WidgetTester tester, String number) async {
    final List<Map<String, Object?>> rows = await queryServiceOrders(tester);
    return rows.firstWhere(
      (Map<String, Object?> row) => row['number'] == number,
    )['image_path'];
  }

  testWidgets('attaching a chosen file stores only its relative path', (
    WidgetTester tester,
  ) async {
    await seedOrder(tester);
    final String source = writeSourceFile('compressor.jpg', 'primeira imagem');
    await pumpServiceOrdersModule(tester, pickImage: () async => source);
    await openDetail(tester, 'OS-2026-0001');

    await tapAttach(tester);

    expect(
      await storedImagePathOf(tester, 'OS-2026-0001'),
      'images/OS-2026-0001.jpg',
    );
    expect(
      File(storedImagePath('OS-2026-0001.jpg')).readAsStringSync(),
      'primeira imagem',
    );
    expect(displayedImagePath(tester), storedImagePath('OS-2026-0001.jpg'));
    expect(inSnackBar('Imagem anexada.'), findsOneWidget);
  });

  testWidgets('attaching again replaces the file and leaves no leftover', (
    WidgetTester tester,
  ) async {
    await seedOrder(tester);
    String picked = writeSourceFile('compressor.jpg', 'primeira imagem');
    await pumpServiceOrdersModule(tester, pickImage: () async => picked);
    await openDetail(tester, 'OS-2026-0001');
    await tapAttach(tester);

    picked = writeSourceFile('compressor-novo.jpg', 'segunda imagem');
    await tapAttach(tester);

    expect(
      File(storedImagePath('OS-2026-0001.jpg')).readAsStringSync(),
      'segunda imagem',
    );
    expect(imagesDirectoryFileNames(), <String>['OS-2026-0001.jpg']);
    expect(
      await storedImagePathOf(tester, 'OS-2026-0001'),
      'images/OS-2026-0001.jpg',
    );
  });

  testWidgets('the attached image survives the deletion of the chosen file', (
    WidgetTester tester,
  ) async {
    await seedOrder(tester);
    final String source = writeSourceFile('compressor.jpg', 'primeira imagem');
    await pumpServiceOrdersModule(tester, pickImage: () async => source);
    await openDetail(tester, 'OS-2026-0001');
    await tapAttach(tester);

    File(source).deleteSync();
    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.backButtonKey),
    );
    await openDetail(tester, 'OS-2026-0001');

    expect(displayedImagePath(tester), storedImagePath('OS-2026-0001.jpg'));
    expect(
      File(storedImagePath('OS-2026-0001.jpg')).readAsStringSync(),
      'primeira imagem',
    );
    expect(find.text(ServiceOrderDetailView.imageMissingMessage), findsNothing);
  });

  testWidgets('removing the image deletes the file and clears the column', (
    WidgetTester tester,
  ) async {
    await seedOrder(tester, imagePath: 'images/OS-2026-0001.jpg');
    File(storedImagePath('OS-2026-0001.jpg'))
      ..createSync(recursive: true)
      ..writeAsStringSync('primeira imagem');
    await pumpServiceOrdersModule(tester);
    await openDetail(tester, 'OS-2026-0001');

    await revealAndTap(
      tester,
      find.byKey(ServiceOrderDetailView.removeImageButtonKey),
    );
    await tapAndSettle(
      tester,
      find.byKey(ServiceOrdersModule.confirmRemoveImageButtonKey),
    );

    expect(await storedImagePathOf(tester, 'OS-2026-0001'), isNull);
    expect(imagesDirectoryFileNames(), isEmpty);
    expect(displayedImagePath(tester), isNull);
    expect(
      find.byKey(ServiceOrderDetailView.attachImageButtonKey),
      findsOneWidget,
    );
    expectNoDialogs();
  });

  testWidgets('a file with an extension outside the accepted list is refused', (
    WidgetTester tester,
  ) async {
    await seedOrder(tester);
    final String source = writeSourceFile('manual.pdf', 'documento');
    await pumpServiceOrdersModule(tester, pickImage: () async => source);
    await openDetail(tester, 'OS-2026-0001');

    await tapAttach(tester);

    expect(await storedImagePathOf(tester, 'OS-2026-0001'), isNull);
    expect(imagesDirectoryFileNames(), isEmpty);
    expect(displayedImagePath(tester), isNull);
    expect(
      inSnackBar(ServiceOrderController.unacceptedImageMessage),
      findsOneWidget,
    );
  });

  for (final String status in <String>['completed', 'cancelled']) {
    testWidgets('an order with status $status offers no image action', (
      WidgetTester tester,
    ) async {
      await seedOrder(
        tester,
        status: status,
        imagePath: 'images/OS-2026-0001.jpg',
      );
      File(storedImagePath('OS-2026-0001.jpg'))
        ..createSync(recursive: true)
        ..writeAsStringSync('primeira imagem');
      await pumpServiceOrdersModule(tester);

      await openDetail(tester, 'OS-2026-0001');

      expect(
        find.byKey(ServiceOrderDetailView.attachImageButtonKey),
        findsNothing,
      );
      expect(
        find.byKey(ServiceOrderDetailView.removeImageButtonKey),
        findsNothing,
      );
    });
  }

  testWidgets('an order without an image shows the placeholder and action', (
    WidgetTester tester,
  ) async {
    await seedOrder(tester, number: 'OS-2026-0002');
    await pumpServiceOrdersModule(tester);

    await openDetail(tester, 'OS-2026-0002');

    expect(
      find.byKey(ServiceOrderDetailView.attachImageButtonKey),
      findsOneWidget,
    );
    expect(find.text('Anexar imagem'), findsOneWidget);
    expect(imageInDetail(), findsNothing);
    expect(find.text(ServiceOrderDetailView.imageMissingMessage), findsNothing);
    expectNoTechnicalErrorText();
  });

  testWidgets('a stored path without a file on disk shows it is unavailable', (
    WidgetTester tester,
  ) async {
    await seedOrder(
      tester,
      number: 'OS-2026-0003',
      imagePath: 'images/OS-2026-0003.jpg',
    );
    await pumpServiceOrdersModule(tester);

    await openDetail(tester, 'OS-2026-0003');

    expect(find.text('Imagem não encontrada.'), findsOneWidget);
    expect(
      find.byKey(ServiceOrderDetailView.attachImageButtonKey),
      findsOneWidget,
    );
    expect(imageInDetail(), findsNothing);
    expectNoTechnicalErrorText();
    expectNoDialogs();
  });

  testWidgets('a large image does not grow the database file', (
    WidgetTester tester,
  ) async {
    await seedOrder(tester);
    final String source = writeSourceFile(
      'compressor.jpg',
      'i' * (3 * 1024 * 1024),
    );
    await pumpServiceOrdersModule(tester, pickImage: () async => source);
    await openDetail(tester, 'OS-2026-0001');
    final File databaseFile = File(
      p.join(
        temporaryDatabase.directory.path,
        DatabaseHelper.databaseFileName,
      ),
    );
    final int sizeBefore = databaseFile.lengthSync();

    await tapAttach(tester);

    expect(
      await storedImagePathOf(tester, 'OS-2026-0001'),
      'images/OS-2026-0001.jpg',
    );
    expect(
      File(storedImagePath('OS-2026-0001.jpg')).lengthSync(),
      3 * 1024 * 1024,
    );
    expect(databaseFile.lengthSync() - sizeBefore, lessThan(64 * 1024));
  });
}
