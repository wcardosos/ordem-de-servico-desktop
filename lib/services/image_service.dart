import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  static String? baseDirectoryOverride;

  static const String imagesDirectoryName = 'images';

  static const List<String> acceptedExtensions = <String>['jpg', 'jpeg', 'png'];

  Future<String> save(String sourcePath, String orderNumber) async {
    final String extension = p.extension(sourcePath).toLowerCase();
    final Directory directory = Directory(
      p.join(await _baseDirectoryPath(), imagesDirectoryName),
    );
    await directory.create(recursive: true);
    for (final String accepted in acceptedExtensions) {
      final File previous = File(
        p.join(directory.path, '$orderNumber.$accepted'),
      );
      if (await previous.exists()) {
        await previous.delete();
      }
    }
    await File(
      sourcePath,
    ).copy(p.join(directory.path, '$orderNumber$extension'));
    return '$imagesDirectoryName/$orderNumber$extension';
  }

  Future<void> remove(String relativePath) async {
    final File file = File(await absolutePath(relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> absolutePath(String relativePath) async {
    return p.join(await _baseDirectoryPath(), relativePath);
  }

  Future<bool> exists(String relativePath) async {
    return File(await absolutePath(relativePath)).exists();
  }

  Future<String> _baseDirectoryPath() async {
    final String? override = baseDirectoryOverride;
    if (override != null) {
      return override;
    }
    return (await getApplicationSupportDirectory()).path;
  }
}
