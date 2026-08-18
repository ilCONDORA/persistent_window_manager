import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:screen_retriever/screen_retriever.dart';

part 'pwm_state.dart';

class PersistentWindowManagerCubit extends HydratedCubit<PersistentWindowManagerState> {
  /// Cubit that persists and restores desktop window size, position, maximized and full-screen state using [HydratedCubit].
  ///
  /// Exposes [changeWindowSize], [changeWindowPosition], [setWindowMaximizedState] and [setWindowFullScreenState].
  /// Resize/move updates are debounced to avoid excessive writes during drag.
  ///
  /// **IMPORTANT:**
  /// [HydratedBloc.storage] must be initialised via [HydratedStorage.build] before this cubit is instantiated.
  PersistentWindowManagerCubit() : super(PersistentWindowManagerInitial()) {
    _init();
  }

  Future<void> _init() async {
    assert(
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
    );

    await setPositionScaleFactor();
  }

  static PersistentWindowManagerCubit? _instance;

  /// Instance of the [PersistentWindowManagerCubit] to be used across the application.
  static PersistentWindowManagerCubit get instance => _instance ??= PersistentWindowManagerCubit();

  // Debounce timers to avoid emitting state too frequently (e.g., during drag and resize).
  Timer? _sizeDebounce;
  Timer? _positionDebounce;
  final Duration _debounceDuration = const Duration(milliseconds: 250);

  /// Fetches the primary display's scale factor and updates the state if it has changed.
  Future<void> setPositionScaleFactor() async {
    final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final double scaleFactor = primaryDisplay.scaleFactor?.toDouble() ?? 1.0;

    if (state.positionScaleFactor != scaleFactor) {
      emit(state.copyWith(positionScaleFactor: scaleFactor));
    }
  }

  /// Method called to change the state of the window size.
  void changeWindowSize(Size newSize) {
    if (state.windowSize == newSize) return;

    _sizeDebounce?.cancel();
    _sizeDebounce = Timer(_debounceDuration, () {
      if (state.windowSize != newSize) {
        emit(state.copyWith(windowSize: newSize));
      }
    });
  }

  /// Saves position as primary-logical pixels: rawPosition × (currentMonitorScale / primaryScale).
  /// [currentMonitorScale] must be [MediaQuery.devicePixelRatioOf] of the monitor the window is on.
  void changeWindowPosition({required Offset rawPosition, required double currentMonitorScale}) {
    final double primaryScale = state.positionScaleFactor ?? 1.0;
    final Offset normalizedPosition = rawPosition * (currentMonitorScale / primaryScale);

    if (state.windowPosition == normalizedPosition) return;

    _positionDebounce?.cancel();
    _positionDebounce = Timer(_debounceDuration, () {
      if (state.windowPosition != normalizedPosition) {
        emit(state.copyWith(windowPosition: normalizedPosition));
      }
    });
  }

  /// Method called to change the state of the window maximized state.
  void setWindowMaximizedState(bool isMaximized) {
    if (state.isMaximized == isMaximized) return;

    emit(state.copyWith(isMaximized: isMaximized));
  }

  /// Method called to change the state of the window full screen state.
  void setWindowFullScreenState(bool isFullScreen) {
    if (state.isFullScreen == isFullScreen) return;

    emit(state.copyWith(isFullScreen: isFullScreen));
  }

  @override
  Future<void> close() {
    _sizeDebounce?.cancel();
    _positionDebounce?.cancel();
    _instance = null;
    return super.close();
  }

  @override
  PersistentWindowManagerState? fromJson(Map<String, dynamic> json) {
    return PersistentWindowManagerState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(PersistentWindowManagerState state) {
    return state.toJson();
  }
}
