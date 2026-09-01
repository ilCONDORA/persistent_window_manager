import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import '../cubit/pwm_cubit.dart';
import '../utils/pwm_utils.dart';

/// A wrapper widget that listens to window events and updates the state of the [PersistentWindowManagerCubit] accordingly.
///
/// It wraps the widget with this (only when [PWMUtils.activatePersistentWindowManager] returned `true`) so size,
/// position, maximized and full-screen changes get persisted automatically.
class PersistentWindowWrapper extends StatefulWidget {
  /// Constructor for [PersistentWindowWrapper]. It takes the app's root [child] widget, which will be wrapped by
  /// this widget to provide window management functionality.
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
