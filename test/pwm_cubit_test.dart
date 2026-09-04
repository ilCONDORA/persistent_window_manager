import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';

import 'test_utils.dart';

void main() {
  late MockStorage storage;
  late PersistentWindowManagerCubit cubit;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() {
    storage = MockStorage();
    initializeMockStorage(storage);
    setUpChannelMocks();
    cubit = PersistentWindowManagerCubit.instance;
  });

  tearDown(() async {
    await cubit.close();
    clearChannelMocks();
  });

  test('setPrimaryDisplayScale reads scaleFactor from the primary display', () async {
    // Override: scaleFactor = 2.0 so the if-branch in setPrimaryDisplayScale is exercised.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.leanflutter.plugins/screen_retriever'),
      (call) async => call.method == 'getPrimaryDisplay'
          ? {
              'id': '1',
              'name': 'T',
              'size': {'width': 1920.0, 'height': 1080.0},
              'scaleFactor': 2.0
            }
          : null,
    );

    await cubit.setPrimaryDisplayScale(); // _primaryDisplayScale → 2.0
    cubit.setCurrentMonitorScale(4.0); // _currentMonitorScale = 4.0
    cubit.startWindowStatePolling();
    await pumpEventQueue(times: 30);

    // position = 100 × (4.0 / 2.0) = 200; would be 400 if primary remained 1.0
    expect(cubit.state.windowPosition, const Offset(200, 200));
  });

  test('setCurrentMonitorScale: accepts valid scale, rejects ≤ 0, ignores same value', () async {
    cubit.setCurrentMonitorScale(2.0); // valid → _currentMonitorScale = 2.0
    cubit.setCurrentMonitorScale(0.0); // ≤ 0 → rejected
    cubit.setCurrentMonitorScale(2.0); // same value → no-op
    cubit.startWindowStatePolling();
    await pumpEventQueue(times: 30);

    // _currentMonitorScale = 2.0, primary = 1.0 → position = 100 × 2.0 = 200
    expect(cubit.state.windowPosition, const Offset(200, 200));
  });

  group('startWindowStatePolling', () {
    test('immediate poll updates size, position, and flags', () async {
      cubit.startWindowStatePolling();
      await pumpEventQueue(times: 30);

      expect(cubit.state.windowSize, const Size(800, 600));
      expect(cubit.state.windowPosition, const Offset(100, 100));
      expect(cubit.state.isMaximized, isFalse);
      expect(cubit.state.isFullScreen, isFalse);
    });

    test('duplicate call is a no-op (timer-guard fires, logs warning)', () async {
      cubit.startWindowStatePolling();
      cubit.startWindowStatePolling(); // _pollingTimer != null → guard
      await pumpEventQueue(times: 30);

      expect(cubit.state.windowSize, const Size(800, 600));
    });
  });

  group('polling skips getSize/getPosition when window is', () {
    test('maximized', () async {
      setUpWindowManagerMockWith(isMaximized: true);
      cubit.startWindowStatePolling();
      await pumpEventQueue(times: 30);

      expect(cubit.state.windowSize, isNull);
      expect(cubit.state.windowPosition, isNull);
      expect(cubit.state.isMaximized, isTrue);
    });

    test('minimized', () async {
      setUpWindowManagerMockWith(isMinimized: true);
      cubit.startWindowStatePolling();
      await pumpEventQueue(times: 30);

      expect(cubit.state.windowSize, isNull);
      expect(cubit.state.windowPosition, isNull);
    });

    test('fullscreen', () async {
      setUpWindowManagerMockWith(isFullScreen: true);
      cubit.startWindowStatePolling();
      await pumpEventQueue(times: 30);

      expect(cubit.state.windowSize, isNull);
      expect(cubit.state.windowPosition, isNull);
      expect(cubit.state.isFullScreen, isTrue);
    });
  });

  test('polling does not emit when the state is already up-to-date', () {
    fakeAsync((fake) {
      cubit.startWindowStatePolling();
      fake.flushMicrotasks(); // first poll sets state

      final stateAfterFirstPoll = cubit.state;

      fake.elapse(const Duration(milliseconds: 750)); // timer → second poll
      fake.flushMicrotasks(); // second poll completes with same values

      expect(cubit.state, same(stateAfterFirstPoll));
    });
  });

  test('_isPolling guard skips a concurrent poll tick', () {
    fakeAsync((fake) {
      final completer = Completer<bool>(); // created inside fake zone
      setUpWindowManagerMockBlocking(completer);

      cubit.startWindowStatePolling();
      // First poll is suspended at: await windowManager.isMinimized()

      fake.elapse(const Duration(milliseconds: 750));
      // Timer fires → second _pollWindowState() call → _isPolling is true → guard returns

      expect(cubit.state.windowSize, isNull); // first poll not yet done

      completer.complete(false); // unblock first poll
      fake.flushMicrotasks(); // first poll completes, state updates

      expect(cubit.state.windowSize, const Size(800, 600));

      setUpChannelMocks(); // restore for tearDown
    });
  });

  test('polling recovers after an error (_isPolling resets in finally)', () {
    fakeAsync((fake) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          if (call.method == 'isMinimized') throw Exception('channel error');
          return null;
        },
      );

      cubit.startWindowStatePolling();
      fake.flushMicrotasks(); // first poll: throws → catch, _isPolling = false in finally

      setUpChannelMocks(); // restore working mock
      fake.elapse(const Duration(milliseconds: 750)); // second poll: succeeds
      fake.flushMicrotasks();

      expect(cubit.state.windowSize, const Size(800, 600));
    });
  });

  group('serialization', () {
    test('toJson / fromJson round-trip preserves all fields', () {
      const state = PersistentWindowManagerState(
        windowSize: Size(1280, 720),
        windowPosition: Offset(50, 75),
        isMaximized: true,
      );
      expect(cubit.fromJson(cubit.toJson(state)!), equals(state));
    });

    test('fromJson handles null optional fields', () {
      final state = cubit.fromJson({
        'windowSize': null,
        'windowPosition': null,
        'isMaximized': false,
        'isFullScreen': false,
      });
      expect(state?.windowSize, isNull);
      expect(state?.windowPosition, isNull);
    });
  });

  test('close cancels the polling timer and resets the singleton', () async {
    cubit.startWindowStatePolling(); // ensures _pollingTimer != null
    await cubit.close();

    final newCubit = PersistentWindowManagerCubit.instance;
    expect(newCubit, isNot(same(cubit)));
    cubit = newCubit; // hand off to tearDown
  });
}
