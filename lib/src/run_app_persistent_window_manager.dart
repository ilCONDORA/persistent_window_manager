// coverage:ignore-file

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'cubit/pwm_cubit.dart';
import 'models/custom_window_options.dart';
import 'widgets/persistent_window_wrapper.dart';

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
}) async {
  if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    runApp(app);
    return;
  }

  await _prepareWindow(windowOptions);
  runApp(PersistentWindowWrapper(child: app));
}

/// Prepares the window according to the saved state and provided options.
/// This includes setting the size, position, maximized state, and full-screen state.
Future<void> _prepareWindow(CustomWindowOptions? windowOptions) async {
  await windowManager.ensureInitialized();

  final PersistentWindowManagerCubit cubit = PersistentWindowManagerCubit.instance;

  // Await explicitly so positions are normalised against the correct scale factor.
  await cubit.setPositionScaleFactor();

  final PersistentWindowManagerState windowState = cubit.state;

  // Not awaited — registers a callback that fires after Flutter's first frame,
  // while the window is still hidden. The window becomes visible only after
  // show() is called inside the callback, already at the correct geometry.
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (windowState.windowSize != null) {
      await windowManager.setSize(windowState.windowSize!);
    }

    if (windowState.windowPosition != null) {
      await windowManager.setPosition(windowState.windowPosition!);
    } else {
      await _centerWindowOnPrimaryDisplay();
    }

    if (windowState.isMaximized) {
      await windowManager.maximize();
    }

    if (windowState.isFullScreen) {
      await windowManager.setFullScreen(true);
    }

    await windowManager.show();
    await windowManager.focus();
  });
}

/// Centers the window on the primary display, respecting its visible area.
Future<void> _centerWindowOnPrimaryDisplay() async {
  final Display primary = await screenRetriever.getPrimaryDisplay();
  final Offset? vp = primary.visiblePosition;
  final Size? vs = primary.visibleSize;
  if (vp == null || vs == null) {
    await windowManager.center();
    return;
  }

  final Size windowSize = await windowManager.getSize();

  // visiblePosition/Size are already in primary-logical space (ratio = 1.0),
  // the same coordinate space setPosition() expects.
  await windowManager.setPosition(
    Offset(
      vp.dx + (vs.width - windowSize.width) / 2,
      vp.dy + (vs.height - windowSize.height) / 2,
    ),
  );
}

/// Exposes the window-setup phase without calling [runApp]; for testing only.
@visibleForTesting
Future<void> setupWindowManagerForTest({CustomWindowOptions? windowOptions}) => _prepareWindow(windowOptions);
