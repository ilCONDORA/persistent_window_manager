import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'cubit/pwm_cubit.dart';
import 'models/custom_window_options.dart';
import 'utils/logging_service.dart';
import 'widgets/persistent_window_wrapper.dart';

// runApp() cannot be invoked in unit tests.
// coverage:ignore-start
/// Replaces [runApp] with window-persistence support for desktop platforms.
///
/// On desktop (Windows, macOS, Linux): initialises [windowManager], registers
/// a [WindowManager.waitUntilReadyToShow] callback that restores saved geometry before the
/// window becomes visible (true zero-flicker), then calls [runApp] with [app]
/// wrapped in [PersistentWindowWrapper] so future window events are tracked.
///
/// On web / mobile: delegates directly to [runApp] with no side-effects.
///
/// **IMPORTANT:** [HydratedBloc.storage] must be initialised before calling this.
Future<void> runAppPersistentWindowManager(
  Widget app, {
  CustomWindowOptions? windowOptions,
  bool enableWindowStateLogging = false,
}) async {
  if (enableWindowStateLogging) LoggingService.instance.enable();

  if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    LoggingService.instance.logInfo('Running app without window persistence.');
    runApp(app);
    return;
  }

  await _prepareWindow(windowOptions);
  LoggingService.instance.logInfo('Running app with window persistence.');
  runApp(PersistentWindowWrapper(child: app));
}
// coverage:ignore-end

/// Prepares the window according to the saved state and provided options.
/// This includes setting the size, position, maximized state, and full-screen state.
Future<void> _prepareWindow(CustomWindowOptions? windowOptions) async {
  LoggingService.instance.logInfo('Preparing window with options: $windowOptions');

  await windowManager.ensureInitialized();

  LoggingService.instance.logInfo('Initializing PersistentWindowManagerCubit instance.');
  final PersistentWindowManagerCubit cubit = PersistentWindowManagerCubit.instance;

  // Sets the primary display scale before any window operations.
  //! Don't touch this, it's a key part of the window management logic.
  await cubit.setPrimaryDisplayScale();

  final PersistentWindowManagerState windowState = cubit.state;
  LoggingService.instance.logInfo('Retrieved window state: $windowState');

  LoggingService.instance.logInfo('Preparing to show window with retrieved state.');
  // Not awaited — registers a callback that fires after Flutter's first frame,
  // while the window is still hidden. The window becomes visible only after
  // show() is called inside the callback, already at the correct geometry.
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // coverage:ignore-start
    if (windowState.windowSize != null) {
      LoggingService.instance.logInfo('Setting window size to: ${windowState.windowSize}');
      await windowManager.setSize(windowState.windowSize!);
    }

    if (windowState.windowPosition != null) {
      LoggingService.instance.logInfo('Setting window position to: ${windowState.windowPosition}');
      await windowManager.setPosition(windowState.windowPosition!);
    } else {
      LoggingService.instance.logInfo('Centering window on primary display because no saved position is available.');
      await _centerWindowOnPrimaryDisplay();
    }

    if (windowState.isMaximized) {
      LoggingService.instance.logInfo('Maximizing window.');
      await windowManager.maximize();
    }

    if (windowState.isFullScreen) {
      LoggingService.instance.logInfo('Setting window to full-screen mode.');
      await windowManager.setFullScreen(true);
    }

    LoggingService.instance.logInfo('Showing and focusing window.');
    await windowManager.show();
    await windowManager.focus();
    // coverage:ignore-end
  });

  // Starts polling the window state (size, position, maximized, full-screen) every 750 milliseconds.
  //! Don't touch this, it's a key part of the window management logic.
  cubit.startWindowStatePolling();

  LoggingService.instance.logInfo('Window prepared successfully.');
}

// Only reachable from the ignored waitUntilReadyToShow callback.
// coverage:ignore-start
/// Centers the window on the primary display, respecting its visible area.
Future<void> _centerWindowOnPrimaryDisplay() async {
  final Display primary = await screenRetriever.getPrimaryDisplay();
  final Offset? vp = primary.visiblePosition;
  final Size? vs = primary.visibleSize;
  if (vp == null || vs == null) {
    LoggingService.instance
        .logWarning('Primary display visible position or size is not available. Centering window as fallback.');
    await windowManager.center();
    return;
  }

  final Size windowSize = await windowManager.getSize();

  LoggingService.instance.logInfo('Centering window on primary display with calculated position.');
  // visiblePosition/Size are already in primary-logical space (ratio = 1.0),
  // the same coordinate space setPosition() expects.
  await windowManager.setPosition(
    Offset(
      vp.dx + (vs.width - windowSize.width) / 2,
      vp.dy + (vs.height - windowSize.height) / 2,
    ),
  );
}

// coverage:ignore-end

/// Exposes the window-setup phase without calling [runApp]; for testing only.
@visibleForTesting
Future<void> setupWindowManagerForTest({CustomWindowOptions? windowOptions}) => _prepareWindow(windowOptions);
