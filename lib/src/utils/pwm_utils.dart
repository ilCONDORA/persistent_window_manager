//coverage:ignore-file

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../cubit/pwm_cubit.dart';
import '../models/custom_window_options.dart';
import '../pe_wi_ma_wrapper.dart';
import '../widgets/persistent_window_wrapper.dart';

/// Utility class for managing persistent window state, including size, position, maximized, and full-screen state.
class PWMUtils {
  /// Used to initialize the window management system for desktop platforms (Windows, macOS, Linux).
  ///
  /// Restores the previously saved size, position, maximized and full-screen state from [PersistentWindowManagerCubit.instance]
  /// before showing the window, so the app reopens exactly where the user left it.
  ///
  /// Returns `true` if the window manager was activated successfully (i.e. running on a desktop platform),
  /// `false` otherwise (web or mobile), so that [PeWiMaWrapper] can wrap the widget in [PersistentWindowWrapper].
  static Future<bool> activatePersistentWindowManager({CustomWindowOptions? windowOptions}) async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return false;
    }

    await windowManager.ensureInitialized();

    /// In the state everything is saved, position, size, if it's maximized or in full screen,
    /// so when the app is opened again it will be in the same state as it was before closing.
    final PersistentWindowManagerState windowState = PersistentWindowManagerCubit.instance.state;

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
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

    return true;
  }

  /// Centers the window on the primary display, taking into account the visible area of the display.
  static Future<void> _centerWindowOnPrimaryDisplay() async {
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
}
