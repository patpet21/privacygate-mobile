import 'dart:io';

import 'package:flutter/services.dart';

class PlatformPrivateStorage {
  static const MethodChannel _channel = MethodChannel(
    'com.aipmlab.privacygate/vault',
  );

  Future<Directory> libraryDirectory() async {
    final path = await _channel.invokeMethod<String>('libraryDirectoryPath');
    if (path == null || path.trim().isEmpty) {
      throw StateError('Platform Library directory is unavailable');
    }
    return Directory(path);
  }
}
