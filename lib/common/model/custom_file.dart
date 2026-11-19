import 'dart:io';

import 'package:mime/mime.dart';
import 'package:field_crm/common/enum/file_type.dart';

class CustomFile {
  final FileType fileType;
  final File file;

  File get thumbnail => file;

  CustomFile({
    required this.fileType,
    required this.file,
  });

  static Future<CustomFile> fromFileAsync(File file) async {
    final type = _getFileType(file);
    return CustomFile(fileType: type, file: file);
  }

  factory CustomFile.fromFile(File file) {
    final type = _getFileType(file);
    return CustomFile(fileType: type, file: file);
  }

  static FileType _getFileType(File file) {
    final mimeType = lookupMimeType(file.path);

    if (mimeType != null) {
      if (mimeType.startsWith('image/')) {
        return FileType.image;
      }
    }

    // Fallback to file extension check if MIME type is not available
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'gif') {
      return FileType.image;
    }

    return FileType.unknown;
  }
}
