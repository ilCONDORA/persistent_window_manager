import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/logging_service.dart';

part 'pwm_state.dart';

/// Persists and restores desktop window size, position, maximized and full-screen state.
/// Window size and position are refreshed every 750 milliseconds while the window is not minimized, maximized, or full-screen.
/// Window maximized and full-screen states are refreshed every 750 milliseconds as well.
///
/// Positions are normalised to primary-logical pixels so they survive monitor DPI changes.
///
/// **IMPORTANT:** [HydratedBloc.storage] must be initialised before this cubit is instantiated.
class PersistentWindowManagerCubit extends HydratedCubit<PersistentWindowManagerState> {
  PersistentWindowManagerCubit()
      : assert(
          () {
            try {
              HydratedBloc.storage;
              return true;
              // coverage:ignore-start
            } catch (_) {
              return false;
            }
            // coverage:ignore-end
          }(),
          'HydratedBloc.storage is not initialized. Please ensure that HydratedBloc.storage is set using HydratedStorage.build() in the main().',
        ),
        super(PersistentWindowManagerInitial());

  static PersistentWindowManagerCubit? _instance;
  static PersistentWindowManagerCubit get instance => _instance ??= PersistentWindowManagerCubit();

  Timer? _pollingTimer;
  bool _isPolling = false;
  double _primaryDisplayScale = 1.0;
  double? _currentMonitorScale;

  /// Sets the primary display scale (DPR) for the primary monitor.
  /// Will be used to normalize window coordinates across different monitors.
  ///
  /// ! REALLY IMPORTANT. Don't touch this, it's a key part of the window management logic.
  Future<void> setPrimaryDisplayScale() async {
    LoggingService.instance.logInfo('Setting primary display scale...');
    final double getScale = (await screenRetriever.getPrimaryDisplay()).scaleFactor?.toDouble() ?? 1.0;

    if (_primaryDisplayScale != getScale) {
      _primaryDisplayScale = getScale;
      LoggingService.instance.logInfo('Primary display scale set to: $_primaryDisplayScale');
    }
  }

  /// Sets the current monitor scale (DPR) for the monitor hosting the window.
  void setCurrentMonitorScale(double scale) {
    if ((scale <= 0, _currentMonitorScale != scale) case (false, true)) {
      _currentMonitorScale = scale;
      LoggingService.instance.logInfo('Monitor changed, monitor scale set to: $_currentMonitorScale');
    }
  }

  /// Starts polling the window state (size, position, maximized, full-screen) every 750 milliseconds.
  /// Polling stops automatically when the cubit is closed.
  void startWindowStatePolling() {
    LoggingService.instance.logInfo('Starting window state polling.');
    // If it is already polling, do nothing.
    if (_pollingTimer != null) {
      LoggingService.instance.logWarning('Window state polling is already active.');
      return;
    }

    _pollingTimer = Timer.periodic(
      Duration(milliseconds: 750),
      (timer) => unawaited(_pollWindowState()),
    );

    unawaited(_pollWindowState());
  }

  /// Polls the window state and updates the cubit's state accordingly.
  Future<void> _pollWindowState() async {
    LoggingService.instance.logInfo('Window state polling started.');

    // Skip this tick if the previous poll hasn't finished yet.
    if (_isPolling) {
      LoggingService.instance.logWarning('Previous window state poll is still in progress. Skipping this tick.');
      return;
    }
    _isPolling = true;

    try {
      LoggingService.instance.logInfo('Polling window minimized, maximized, and full-screen state...');
      final bool minimized = await windowManager.isMinimized();
      final bool maximized = await windowManager.isMaximized();
      final bool fullScreen = await windowManager.isFullScreen();
      LoggingService.instance
          .logInfo('Window state: minimized=$minimized, maximized=$maximized, fullScreen=$fullScreen');

      Size? newSize = state.windowSize;
      Offset? newPosition = state.windowPosition;
      LoggingService.instance.logInfo('Current window size: $newSize, position: $newPosition');

      // If the window is NOT minimized, maximized, or full-screen, we update its size and position.
      if (!(minimized || maximized || fullScreen)) {
        newSize = await windowManager.getSize();
        LoggingService.instance.logInfo('Updated window size: $newSize');

        // Sets the window position as primary-logical pixels: rawPosition × (currentMonitorScale / primaryDisplayScale).
        final Offset rawPosition = await windowManager.getPosition();
        newPosition = rawPosition * ((_currentMonitorScale ?? _primaryDisplayScale) / _primaryDisplayScale);
        LoggingService.instance.logInfo('Updated window position: $newPosition');
      }

      final bool hasChanges = state.isMaximized != maximized ||
          state.isFullScreen != fullScreen ||
          state.windowSize != newSize ||
          state.windowPosition != newPosition;
      LoggingService.instance.logInfo('Has window state changes: $hasChanges');

      if (hasChanges) {
        LoggingService.instance.logInfo('Emitting new window state...');
        emit(state.copyWith(
          isMaximized: maximized,
          isFullScreen: fullScreen,
          windowSize: newSize,
          windowPosition: newPosition,
        ));
        LoggingService.instance.logInfo('New window state emitted.');
      }
    } catch (e, stackTrace) {
      LoggingService.instance.logError('Error while polling window state.', error: e, stackTrace: stackTrace);
    } finally {
      _isPolling = false;
      LoggingService.instance.logInfo('Window state polling completed.');
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _instance = null;
    return super.close();
  }

  @override
  PersistentWindowManagerState? fromJson(Map<String, dynamic> json) => PersistentWindowManagerState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(PersistentWindowManagerState state) => state.toJson();
}
