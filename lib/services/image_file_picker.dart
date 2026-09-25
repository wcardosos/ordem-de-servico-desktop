import 'package:file_selector/file_selector.dart';

import 'image_service.dart';

typedef ImageFilePicker = Future<String?> Function();

Future<String?> pickImageFile() async {
  final XFile? picked = await openFile(
    acceptedTypeGroups: <XTypeGroup>[
      XTypeGroup(label: 'Imagens', extensions: ImageService.acceptedExtensions),
    ],
    confirmButtonText: 'Selecionar',
  );
  return picked?.path;
}
