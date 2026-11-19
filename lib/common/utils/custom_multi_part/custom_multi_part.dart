import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class CustomMultipart {
  static Future<FormData> awaitParseBody(
    Map<String, dynamic> data, {
    bool removeNull = true,
  }) async {
    final Map<String, dynamic> parsedMap = {};

    for (var entry in data.entries) {
      final result = await _getData(entry, removeNull);
      if (result != null) {
        parsedMap.addAll(result);
      }
    }

    final formData = FormData.fromMap(parsedMap);

    log('--- Multipart FormData ---');
    for (final field in formData.fields) {
      log('Field: ${field.key} = ${field.value}');
    }

    for (final file in formData.files) {
      log('File: ${file.key} => ${file.value.filename}');
    }
    log('---------------------------');

    return formData;
  }

  static Future<Map<String, dynamic>?> _getData(
    MapEntry mapEntry,
    bool removeNull,
  ) async {
    final String key = mapEntry.key.toString();
    final value = mapEntry.value;

    if (value == null && removeNull) return null;

    if (value is List<String>) {
      final List<MultipartFile> fileList = [];

      for (final path in value) {
        final file = File(path);
        if (!await file.exists()) continue;

        final fileName = path.split(Platform.pathSeparator).last;
        final mimeType = _getMimeType(fileName);

        fileList.add(
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      if (fileList.isNotEmpty) return {key: fileList};
      return null;
    }

    if (value is List<File>) {
      final List<MultipartFile> fileList = [];

      for (final file in value) {
        if (!await file.exists()) continue;
        final fileName = file.path.split(Platform.pathSeparator).last;
        final mimeType = _getMimeType(fileName);
        fileList.add(
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      if (fileList.isNotEmpty) return {key: fileList};
      return null;
    }

    if (value is! File) {
      return {key: value};
    }

    if (!await value.exists()) return null;
    final fileName = value.path.split(Platform.pathSeparator).last;
    final mimeType = _getMimeType(fileName);
    return {
      key: await MultipartFile.fromFile(
        value.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    };
  }

  static String _getMimeType(String fileName) {
    final detected = lookupMimeType(fileName);
    if (detected != null && detected.isNotEmpty) return detected;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
