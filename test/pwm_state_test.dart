import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';

void main() {
  const base = PersistentWindowManagerState(
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
    });

    test('overrides windowPosition only', () {
      final result = base.copyWith(windowPosition: const Offset(50, 75));
      expect(result.windowPosition, const Offset(50, 75));
      expect(result.windowSize, base.windowSize);
    });

    test('sets and resets isMaximized', () {
      final maxed = base.copyWith(isMaximized: true);
      expect(maxed.isMaximized, isTrue);
      expect(maxed.copyWith(isMaximized: false).isMaximized, isFalse);
    });

    test('sets and resets isFullScreen', () {
      final fs = base.copyWith(isFullScreen: true);
      expect(fs.isFullScreen, isTrue);
      expect(fs.copyWith(isFullScreen: false).isFullScreen, isFalse);
    });
  });

  group('toJson / fromJson', () {
    test('serializes null optional fields as null', () {
      const state = PersistentWindowManagerState();
      final json = state.toJson();
      expect(json['windowSize'], isNull);
      expect(json['windowPosition'], isNull);
      expect(json['isMaximized'], isFalse);
      expect(json['isFullScreen'], isFalse);
    });

    test('round-trip fromJson(toJson()) produces an equal state', () {
      expect(PersistentWindowManagerState.fromJson(base.toJson()), equals(base));
    });
  });

  group('equality and hashCode', () {
    test('two instances with same values are equal with matching hashCode', () {
      const copy = PersistentWindowManagerState(
        windowSize: Size(800, 600),
        windowPosition: Offset(100, 200),
      );
      expect(base, equals(copy));
      expect(base.hashCode, equals(copy.hashCode));
    });

    test('differs when any field is changed', () {
      expect(base.copyWith(windowSize: const Size(1, 1)), isNot(equals(base)));
      expect(base.copyWith(windowPosition: Offset.zero), isNot(equals(base)));
      expect(base.copyWith(isMaximized: true), isNot(equals(base)));
      expect(base.copyWith(isFullScreen: true), isNot(equals(base)));
    });
  });

  test('PersistentWindowManagerInitial is a PersistentWindowManagerState', () {
    expect(PersistentWindowManagerInitial(), isA<PersistentWindowManagerState>());
  });
}
