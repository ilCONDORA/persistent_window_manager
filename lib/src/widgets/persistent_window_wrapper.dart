import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import '../cubit/pwm_cubit.dart';
import '../run_app_persistent_window_manager.dart';

/// Listens to native window events and persists geometry changes via [PersistentWindowManagerCubit].
///
/// [runAppPersistentWindowManager] wraps the app with this widget automatically on desktop platforms.
class PersistentWindowWrapper extends StatefulWidget {
  /// Listens to native window events and persists geometry changes via [PersistentWindowManagerCubit].
  ///
  /// [runAppPersistentWindowManager] wraps the app with this widget automatically on desktop platforms.
  const PersistentWindowWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<PersistentWindowWrapper> createState() => _PersistentWindowWrapperState();
}

class _PersistentWindowWrapperState extends State<PersistentWindowWrapper> with WindowListener {
  final PersistentWindowManagerCubit pwmCubit = PersistentWindowManagerCubit.instance;

  /// Updates the window position in the [PersistentWindowManagerCubit] based on
  /// the current window position and the device pixel ratio.
  ///
  /// It's EXTREMELY important to call this method whenever the window is moved or resized to ensure
  /// the cubit has the correct datas. We do this because of the ratio of the pixel density of monitors,
  /// especially in multi-monitor setups.
  Future<void> _changeWindowPosition() async {
    final double dpr = MediaQuery.devicePixelRatioOf(context);

    // Guard: don't save position/size while in maximized or fullscreen
    // state. During the transition out of maximize, getPosition() returns
    // a transitional value that may be off-screen.
    final bool maximized = await windowManager.isMaximized();
    final bool fullscreen = await windowManager.isFullScreen();
    if (maximized || fullscreen) {
      return;
    }

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
