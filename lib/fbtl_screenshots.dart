library fbtl_screenshots;

import 'dart:io' show File, Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

import 'fbtl_screenshots_platform_interface.dart';

/// Takes screenshots in a firebase test lab environment and makes them
/// available in the firebase test lab output.
class FBTLScreenshots {
  static const kTimeout = Duration(seconds: 10);
  static const kTimeoutResult = <int>[];
  bool _connected = false;

  /// Warms up the connection to the screenshot handler.
  Future<void> connect() async {
    if (!_connected) {
      if (Platform.isAndroid) {
        await FBTLScreenshotsPlatform.instance.connect();
      }
      _connected = true;
    }
  }

  /// iOS screenshot feature was removed due to binding conflict with Patrol v3.0 library
  /// [APP-3638] https://wehealth.atlassian.net/browse/APP-3638

  /// Takes a screenshot with the given name.
  /// On iOS, the resulting screenshot is attached to the xctest results.
  /// On Android, the screenshot is written to the external storage directory.
  Future<void> takeScreenshot(String name) async {
    if (!_connected) {
      throw FBTLScreenshotsException(
          'Call connect() before taking screenshots');
    }
    if (Platform.isAndroid) {
      return _takeAndroidScreenshot(name);
    } else {
      throw FBTLScreenshotsException(
          'Unsupported platform ${Platform.operatingSystem}');
    }
  }

  Future<void> _takeAndroidScreenshot(String name) async {
    final extStorage = await getExternalStorageDirectory();
    if (extStorage == null) {
      throw FBTLScreenshotsException('No external storage directory');
    }
    final bytes = await FBTLScreenshotsPlatform.instance
        .takeScreenshot()
        .timeout(kTimeout, onTimeout: () => kTimeoutResult);
    if (bytes == null) {
      throw FBTLScreenshotsException(
          'Unexpected fbtl_screenshots failure with no error message');
    }
    if (bytes == kTimeoutResult) {
      throw FBTLScreenshotsException(
          'FBTLScreenshots use of UIAutomator took longer than $kTimeout');
    }
    final dest = File('${extStorage.path}/screenshots/$name.png');
    dest.parent.createSync(recursive: true);
    dest.writeAsBytesSync(bytes, flush: true);
  }
}

class FBTLScreenshotsException implements Exception {
  final String message;

  FBTLScreenshotsException(this.message);

  @override
  String toString() => 'FBTLScreenshotsException: $message';
}
