import 'package:window_manager/window_manager.dart';

import '../run_app_persistent_window_manager.dart';

/// A custom implementation of [WindowOptions] that allows for more flexible window management.
class CustomWindowOptions extends WindowOptions {
  /// Creates a [CustomWindowOptions] instance to pass to [runAppPersistentWindowManager].
  ///
  /// Use this class to specify the window options of the application window.
  const CustomWindowOptions({
    // These 3 properties are commented out because they will be managed internally.
    super.alwaysOnTop,
    super.backgroundColor,
    // super.center,
    // super.fullScreen,
    super.maximumSize,
    super.minimumSize,
    // super.size,
    super.skipTaskbar,
    super.title,
    super.titleBarStyle,
    super.windowButtonVisibility,
  });
}
