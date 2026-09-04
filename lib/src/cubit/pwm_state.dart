part of 'pwm_cubit.dart';

/// Immutable snapshot of window geometry and display state persisted by [PersistentWindowManagerCubit].
@immutable
class PersistentWindowManagerState {
  final Size? windowSize;
  final Offset? windowPosition;
  final bool isMaximized;
  final bool isFullScreen;

  /// All geometry fields are null until the first launch persists them.
  const PersistentWindowManagerState({
    this.windowSize,
    this.windowPosition,
    this.isMaximized = false,
    this.isFullScreen = false,
  });

  /// Returns a new instance with the specified fields replaced.
  PersistentWindowManagerState copyWith({
    Size? windowSize,
    Offset? windowPosition,
    bool? isMaximized,
    bool? isFullScreen,
  }) {
    return PersistentWindowManagerState(
      windowSize: windowSize ?? this.windowSize,
      windowPosition: windowPosition ?? this.windowPosition,
      isMaximized: isMaximized ?? this.isMaximized,
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }

  /// Converts the current state to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'windowSize': windowSize == null
          ? null
          : <String, double>{
              'width': windowSize!.width,
              'height': windowSize!.height,
            },
      'windowPosition': windowPosition == null
          ? null
          : <String, double>{
              'x': windowPosition!.dx,
              'y': windowPosition!.dy,
            },
      'isMaximized': isMaximized,
      'isFullScreen': isFullScreen,
    };
  }

  /// Creates a new instance of [PersistentWindowManagerState] from a JSON map.
  static PersistentWindowManagerState fromJson(Map<String, dynamic> json) {
    return PersistentWindowManagerState(
      windowSize: json['windowSize'] == null
          ? null
          : Size(
              json['windowSize']['width'] as double,
              json['windowSize']['height'] as double,
            ),
      windowPosition: json['windowPosition'] == null
          ? null
          : Offset(
              json['windowPosition']['x'] as double,
              json['windowPosition']['y'] as double,
            ),
      isMaximized: json['isMaximized'] as bool? ?? false,
      isFullScreen: json['isFullScreen'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistentWindowManagerState &&
          runtimeType == other.runtimeType &&
          windowSize == other.windowSize &&
          windowPosition == other.windowPosition &&
          isMaximized == other.isMaximized &&
          isFullScreen == other.isFullScreen;

  @override
  int get hashCode => Object.hash(
        windowSize,
        windowPosition,
        isMaximized,
        isFullScreen,
      );
}

/// Initial state used by [PersistentWindowManagerCubit] on first launch.
final class PersistentWindowManagerInitial extends PersistentWindowManagerState {}
