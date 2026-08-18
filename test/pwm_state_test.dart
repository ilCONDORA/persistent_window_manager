import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';

void main() {
  const base = PersistentWindowManagerState(
    positionScaleFactor: 1.5,
    windowSize: Size(800, 600),
    windowPosition: Offset(100, 200),
  );

  group('copyWith', () {
    test('preserves all values when no arguments are given', () {
      expect(base.copyWith(), equals(base));
    });

    test('overrides windowSize only', () {
      final result = base.copyWith(windowSize: const Size(1920, 1080));
      expect(result.windowSize, const Size(1920, 1080));
      expect(result.windowPosition, base.windowPosition);
      expect(result.positionScaleFactor, base.positionScaleFactor);
    });

    test('overrides windowPosition only', () {
      final result = base.copyWith(windowPosition: const Offset(50, 75));
      expect(result.windowPosition, const Offset(50, 75));
      expect(result.windowSize, base.windowSize);
    });

    test('overrides positionScaleFactor only', () {
      final result = base.copyWith(positionScaleFactor: 2.0);
      expect(result.positionScaleFactor, 2.0);
      expect(result.windowSize, base.windowSize);
    });

    group('boolean flag overrides', () {
      test('sets isMaximized to true', () {
        final result = base.copyWith(isMaximized: true);
        expect(result.isMaximized, isTrue);
        expect(result.isFullScreen, isFalse);
      });

      test('resets isMaximized back to false', () {
        final maximized = base.copyWith(isMaximized: true);
        expect(maximized.copyWith(isMaximized: false).isMaximized, isFalse);
      });

      test('sets isFullScreen to true', () {
        final result = base.copyWith(isFullScreen: true);
        expect(result.isFullScreen, isTrue);
        expect(result.isMaximized, isFalse);
      });

      test('resets isFullScreen back to false', () {
        final fullscreen = base.copyWith(isFullScreen: true);
        expect(fullscreen.copyWith(isFullScreen: false).isFullScreen, isFalse);
      });
    });
  });

  group('toJson', () {
    test('serializes null optional fields as null', () {
      const state = PersistentWindowManagerState();
      final json = state.toJson();
      expect(json['positionScaleFactor'], isNull);
      expect(json['windowSize'], isNull);
      expect(json['windowPosition'], isNull);
      expect(json['isMaximized'], isFalse);
      expect(json['isFullScreen'], isFalse);
    });

    test('serializes all fields into nested maps when set', () {
      final json = base.toJson();
      expect(json['positionScaleFactor'], 1.5);
      expect(json['windowSize'], {'width': 800.0, 'height': 600.0});
      expect(json['windowPosition'], {'x': 100.0, 'y': 200.0});
      expect(json['isMaximized'], isFalse);
      expect(json['isFullScreen'], isFalse);
    });
  });

  group('fromJson', () {
    test('produces null optional fields from an all-null JSON map', () {
      final state = PersistentWindowManagerState.fromJson({
        'positionScaleFactor': null,
        'windowSize': null,
        'windowPosition': null,
        'isMaximized': false,
        'isFullScreen': false,
      });
      expect(state.positionScaleFactor, isNull);
      expect(state.windowSize, isNull);
      expect(state.windowPosition, isNull);
    });

    test('populates all fields from a complete JSON map', () {
      final state = PersistentWindowManagerState.fromJson({
        'positionScaleFactor': 1.5,
        'windowSize': {'width': 800.0, 'height': 600.0},
        'windowPosition': {'x': 100.0, 'y': 200.0},
        'isMaximized': false,
        'isFullScreen': false,
      });
      expect(state, equals(base));
    });

    test('round-trip: fromJson(toJson()) produces an equal state', () {
      expect(PersistentWindowManagerState.fromJson(base.toJson()), equals(base));
    });
  });

  group('equality and hashCode', () {
    test('identical instance equals itself', () {
      expect(base, equals(base));
    });

    test('two instances with same values are equal with matching hashCode', () {
      const copy = PersistentWindowManagerState(
        positionScaleFactor: 1.5,
        windowSize: Size(800, 600),
        windowPosition: Offset(100, 200),
      );
      expect(base, equals(copy));
      expect(base.hashCode, equals(copy.hashCode));
    });

    group('inequality when any field differs', () {
      test('differs on windowSize', () {
        expect(base.copyWith(windowSize: const Size(1, 1)), isNot(equals(base)));
      });

      test('differs on windowPosition', () {
        expect(base.copyWith(windowPosition: Offset.zero), isNot(equals(base)));
      });

      test('differs on positionScaleFactor', () {
        expect(base.copyWith(positionScaleFactor: 2.0), isNot(equals(base)));
      });

      test('differs on isMaximized', () {
        expect(base.copyWith(isMaximized: true), isNot(equals(base)));
      });

      test('differs on isFullScreen', () {
        expect(base.copyWith(isFullScreen: true), isNot(equals(base)));
      });
    });
  });

  test('PersistentWindowManagerInitial is a PersistentWindowManagerState', () {
    expect(PersistentWindowManagerInitial(), isA<PersistentWindowManagerState>());
  });
}
