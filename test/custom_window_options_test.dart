import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';

void main() {
  test('constructor forwards all parameters to WindowOptions', () {
    const options = CustomWindowOptions(
      alwaysOnTop: true,
      backgroundColor: null,
      maximumSize: null,
      minimumSize: Size(400, 300),
      skipTaskbar: false,
      title: 'Test',
      titleBarStyle: null,
      windowButtonVisibility: true,
    );

    expect(options.title, 'Test');
    expect(options.alwaysOnTop, isTrue);
    expect(options.skipTaskbar, isFalse);
    expect(options.windowButtonVisibility, isTrue);
    expect(options.minimumSize, const Size(400, 300));
  });
}
