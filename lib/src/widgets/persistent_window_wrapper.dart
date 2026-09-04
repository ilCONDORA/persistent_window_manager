import 'package:flutter/widgets.dart';

import '../cubit/pwm_cubit.dart';
import '../run_app_persistent_window_manager.dart';

/// Keeps monitor DPR synchronized in [PersistentWindowManagerCubit].
///
/// [runAppPersistentWindowManager] wraps the app with this widget automatically on desktop platforms.
class PersistentWindowWrapper extends StatefulWidget {
  /// Keeps monitor DPR synchronized in [PersistentWindowManagerCubit].
  ///
  /// [runAppPersistentWindowManager] wraps the app with this widget automatically on desktop platforms.
  const PersistentWindowWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<PersistentWindowWrapper> createState() => _PersistentWindowWrapperState();
}

class _PersistentWindowWrapperState extends State<PersistentWindowWrapper> with WidgetsBindingObserver {
  /// Updates the monitor scale in the cubit. It's extemely important because with multi-monitor setups the scales are
  /// different, so this prevents the window from shifting between session end->start.
  void _syncMonitorScale(BuildContext context) => PersistentWindowManagerCubit.instance.setCurrentMonitorScale(
        View.maybeOf(context)?.devicePixelRatio ?? MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    _syncMonitorScale(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
