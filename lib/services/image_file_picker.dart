import 'package:file_picker/file_picker.dart';

import 'image_service.dart';

typedef ImageFilePicker = Future<String?> Function();

Future<String?> pickImageFile() async {
  final PlatformFile? picked = await FilePicker.pickFile(
    dialogTitle: 'Selecionar imagem',
    type: FileType.custom,
    allowedExtensions: ImageService.acceptedExtensions,
  );
  return picked?.path;
}
