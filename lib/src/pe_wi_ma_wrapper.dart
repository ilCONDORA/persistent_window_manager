import 'package:flutter/widgets.dart';
import 'models/custom_window_options.dart';
import 'utils/pwm_utils.dart';
import 'widgets/persistent_window_wrapper.dart';

/// A wrapper widget that activates the persistent window manager and conditionally wraps the
/// child widget with [PersistentWindowWrapper].
class PeWiMaWrapper extends StatefulWidget {
  /// Creates a [PeWiMaWrapper] widget.
  ///
  /// The [child] parameter is the widget that will be wrapped.
  /// The [windowOptions] parameter allows specifying custom window options for the persistent window manager.
  ///
  /// If the persistent window manager is successfully activated, the [child] will be wrapped with [PersistentWindowWrapper].
  /// Otherwise, the [child] will be returned as-is without being wrapped.
  ///
  /// The logic behind the decision to wrap the child with [PersistentWindowWrapper] is based on whether the persistent window manager
  /// was successfully activated and it's determined by the return value of [PWMUtils.activatePersistentWindowManager].
  ///
  /// [PeWiMaWrapper] stands for "Persistent Window Manager Wrapper", it's long so I abbreviated it.
  const PeWiMaWrapper(this.child, {super.key, this.windowOptions});

  /// The child widget that will be conditionally wrapped based on the activation of the persistent window manager.
  final Widget child;

  /// Custom window options for the persistent window manager.
  final CustomWindowOptions? windowOptions;

  @override
  State<PeWiMaWrapper> createState() => _PeWiMaWrapperState();
}

class _PeWiMaWrapperState extends State<PeWiMaWrapper> {
  /// Future that holds the result of the persistent window manager activation.
  late Future<bool> _activationFuture;

  @override
  void initState() {
    super.initState();

    _activationFuture = PWMUtils.activatePersistentWindowManager(
      windowOptions: widget.windowOptions,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _activationFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return PersistentWindowWrapper(child: widget.child);
          }
          return widget.child;
        },
      );
}
