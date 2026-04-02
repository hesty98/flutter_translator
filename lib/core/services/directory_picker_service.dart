import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

class PickedDirectory {
  const PickedDirectory({required this.path, this.bookmark});

  final String path;
  final String? bookmark;
}

class DirectoryPickerService {
  static const MethodChannel _channel = MethodChannel(
    'flutter_translator/directory_picker',
  );

  Future<PickedDirectory?> pickProjectDirectory() async {
    if (!Platform.isMacOS) {
      final path = await getDirectoryPath();
      if (path == null || path.isEmpty) {
        return null;
      }
      return PickedDirectory(path: path);
    }

    final result = await _channel.invokeMapMethod<String, dynamic>(
      'pickProjectDirectory',
    );
    if (result == null) {
      return null;
    }

    final path = result['path'] as String?;
    if (path == null || path.isEmpty) {
      return null;
    }

    return PickedDirectory(path: path, bookmark: result['bookmark'] as String?);
  }
}
