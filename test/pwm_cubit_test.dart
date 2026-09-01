import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';

import 'test_utils.dart';

void _setUpScreenRetrieverMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('dev.leanflutter.plugins/screen_retriever'),
    (MethodCall call) async {
      if (call.method == 'getPrimaryDisplay') {
        return {
          'id': '1',
          'name': 'Test Display',
          'size': {'width': 1920.0, 'height': 1080.0},
          'scaleFactor': 1.0,
        };
      }
      return null;
    },
  );
}

void main() {
  late MockStorage storage;
  late PersistentWindowManagerCubit cubit;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    storage = MockStorage();
    initializeMockStorage(storage);
    _setUpScreenRetrieverMock();

    cubit = PersistentWindowManagerCubit.instance;
    await pumpEventQueue(); // let _init() + setPositionScaleFactor() complete
  });

  tearDown(() async {
    await cubit.close();
  });

  group('setWindowMaximizedState', () {
    test('emits isMaximized: true when previously false', () {
      cubit.setWindowMaximizedState(true);
      expect(cubit.state.isMaximized, isTrue);
    });

    test('emits isMaximized: false after being true', () {
      cubit.setWindowMaximizedState(true);
      cubit.setWindowMaximizedState(false);
      expect(cubit.state.isMaximized, isFalse);
    });

    test('does not change state when value is already the same', () {
      final stateBefore = cubit.state;
      cubit.setWindowMaximizedState(false); // already false
      expect(cubit.state, equals(stateBefore));
    });
  });

  group('setWindowFullScreenState', () {
    test('emits isFullScreen: true when previously false', () {
      cubit.setWindowFullScreenState(true);
      expect(cubit.state.isFullScreen, isTrue);
    });

    test('emits isFullScreen: false after being true', () {
      cubit.setWindowFullScreenState(true);
      cubit.setWindowFullScreenState(false);
      expect(cubit.state.isFullScreen, isFalse);
    });

    test('does not change state when value is already the same', () {
      final stateBefore = cubit.state;
      cubit.setWindowFullScreenState(false); // already false
      expect(cubit.state, equals(stateBefore));
    });
  });

  group('changeWindowSize debounced', () {
    test('emits new windowSize after the debounce period elapses', () {
      fakeAsync((async) {
        cubit.changeWindowSize(const Size(1280, 720));
        async.elapse(const Duration(milliseconds: 300));
        expect(cubit.state.windowSize, const Size(1280, 720));
      });
    });

    test('does not emit when the size already matches the current state', () {
      fakeAsync((async) {
        cubit.changeWindowSize(const Size(1280, 720));
        async.elapse(const Duration(milliseconds: 300));
        final stateBefore = cubit.state;

        cubit.changeWindowSize(const Size(1280, 720));
        async.elapse(const Duration(milliseconds: 300));

        expect(cubit.state, equals(stateBefore));
      });
    });

    test('emits only the last size when called multiple times before the debounce fires', () {
      fakeAsync((async) {
        cubit.changeWindowSize(const Size(800, 600));
        cubit.changeWindowSize(const Size(900, 700));
        cubit.changeWindowSize(const Size(1280, 720));
        async.elapse(const Duration(milliseconds: 300));
        expect(cubit.state.windowSize, const Size(1280, 720));
      });
    });
  });

  group('changeWindowPosition debounced', () {
    test('emits raw offset unchanged when primary and monitor scale are equal', () {
      fakeAsync((async) {
        cubit.changeWindowPosition(
          rawPosition: const Offset(200, 150),
          currentMonitorScale: 1.0,
        );
        async.elapse(const Duration(milliseconds: 300));
        expect(cubit.state.windowPosition, const Offset(200, 150));
      });
    });

    test('normalizes offset when the monitor scale differs from the primary scale', () {
      fakeAsync((async) {
        // primary = 1.0 (from mock), monitor = 2.0 → normalized = raw × (2 / 1)
        cubit.changeWindowPosition(
          rawPosition: const Offset(100, 50),
          currentMonitorScale: 2.0,
        );
        async.elapse(const Duration(milliseconds: 300));
        expect(cubit.state.windowPosition, const Offset(200, 100));
      });
    });

    test('does not emit when the normalized position matches the current state', () {
      fakeAsync((async) {
        cubit.changeWindowPosition(
          rawPosition: const Offset(200, 150),
          currentMonitorScale: 1.0,
        );
        async.elapse(const Duration(milliseconds: 300));
        final stateBefore = cubit.state;

        cubit.changeWindowPosition(
          rawPosition: const Offset(200, 150),
          currentMonitorScale: 1.0,
        );
        async.elapse(const Duration(milliseconds: 300));

        expect(cubit.state, equals(stateBefore));
      });
    });
  });

  group('serialization', () {
    test('toJson reflects the current state', () {
      cubit.setWindowMaximizedState(true);
      final json = cubit.toJson(cubit.state);
      expect(json?['isMaximized'], isTrue);
      expect(json?['isFullScreen'], isFalse);
    });

    test('fromJson deserializes a complete JSON map correctly', () {
      final state = cubit.fromJson({
        'positionScaleFactor': 1.5,
        'windowSize': {'width': 1280.0, 'height': 720.0},
        'windowPosition': {'x': 50.0, 'y': 75.0},
        'isMaximized': true,
        'isFullScreen': false,
      });
      expect(state?.windowSize, const Size(1280, 720));
      expect(state?.windowPosition, const Offset(50, 75));
      expect(state?.isMaximized, isTrue);
    });

    test('fromJson handles null optional fields gracefully', () {
      final state = cubit.fromJson({
        'positionScaleFactor': null,
        'windowSize': null,
        'windowPosition': null,
        'isMaximized': false,
        'isFullScreen': false,
      });
      expect(state?.windowSize, isNull);
      expect(state?.windowPosition, isNull);
    });
  });

  test('a new instance is returned by the instance getter after the singleton is closed', () async {
    await cubit.close();
    final newCubit = PersistentWindowManagerCubit.instance;
    await pumpEventQueue();

    expect(newCubit, isNot(same(cubit)));
    cubit = newCubit; // hand off to tearDown for cleanup
  });
}
