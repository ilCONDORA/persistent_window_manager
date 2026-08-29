import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'cubit/pwm_cubit.dart';

/// A custom implementation of [WindowOptions] that allows for more flexible window management.
class CustomWindowOptions extends WindowOptions {
  /// Creates a [CustomWindowOptions] instance to pass to [activatePersistentWindowManager].
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

// coverage:ignore-start
/// Centers the window on the primary display, taking into account the visible area of the display.
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

/// Used to initialize the window management system for desktop platforms (Windows, macOS, Linux).
///
/// Restores the previously saved size, position, maximized and full-screen state from [PersistentWindowManagerCubit.instance]
/// before showing the window, so the app reopens exactly where the user left it.
///
/// Returns `true` if the window manager was activated (i.e. running on a desktop platform),
/// `false` otherwise (web or mobile), so callers can decide whether to wrap the app in [PersistentWindowWrapper].
Future<bool> activatePersistentWindowManager({CustomWindowOptions? windowOptions}) async {
  // We use the if statement to cut off the window management system.
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
// coverage:ignore-end

/// A wrapper widget that listens to window events and updates the state of the [PersistentWindowManagerCubit] accordingly.
///
/// Wrap your app's root widget with this (only when [activatePersistentWindowManager] returned `true`) so size,
/// position, maximized and full-screen changes get persisted automatically.
class PersistentWindowWrapper extends StatefulWidget {
  /// Constructor for [PersistentWindowWrapper]. It takes the app's root [child] widget, which will be wrapped by
  /// this widget to provide window management functionality.
  const PersistentWindowWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<PersistentWindowWrapper> createState() => _PersistentWindowWrapperState();
}

class _PersistentWindowWrapperState extends State<PersistentWindowWrapper> with WindowListener {
  final PersistentWindowManagerCubit pwmCubit = PersistentWindowManagerCubit.instance;

  Future<void> _changeWindowPosition() async {
    final double dpr = MediaQuery.devicePixelRatioOf(context);

    pwmCubit.changeWindowPosition(rawPosition: await windowManager.getPosition(), currentMonitorScale: dpr);
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      pwmCubit.setWindowMaximizedState(true);
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      pwmCubit.setWindowMaximizedState(false);
    }
  }

  @override
  void onWindowResize() async {
    if (mounted) {
      pwmCubit.changeWindowSize(await windowManager.getSize());

      await _changeWindowPosition();
    }
  }

  @override
  void onWindowMove() async {
    if (mounted) {
      await _changeWindowPosition();
    }
  }

  @override
  void onWindowBlur() async {
    if (mounted) {
      pwmCubit.changeWindowSize(await windowManager.getSize());

      await _changeWindowPosition();
    }
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) {
      pwmCubit.setWindowFullScreenState(true);
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) {
      pwmCubit.setWindowFullScreenState(false);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
