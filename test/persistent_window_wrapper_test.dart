import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';
import 'package:persistent_window_manager/src/widgets/persistent_window_wrapper.dart';
import 'package:window_manager/window_manager.dart';

import 'test_utils.dart';

Widget _buildWrapper({Widget child = const SizedBox()}) {
  return MediaQuery(
    data: const MediaQueryData(devicePixelRatio: 1.0),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: PersistentWindowWrapper(child: child),
    ),
  );
}

void main() {
  late MockStorage storage;
  late PersistentWindowManagerCubit cubit;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    storage = MockStorage();
    initializeMockStorage(storage);
    setUpChannelMocks();

    cubit = PersistentWindowManagerCubit.instance;
    await pumpEventQueue(); // let _init() + setPositionScaleFactor() complete
  });

  tearDown(() async {
    await cubit.close();
    clearChannelMocks();
  });

  test('CustomWindowOptions constructor forwards parameters to WindowOptions', () {
    const options = CustomWindowOptions(
      alwaysOnTop: true,
      backgroundColor: null,
      maximumSize: null,
      minimumSize: null,
      skipTaskbar: false,
      title: 'Test',
      titleBarStyle: null,
      windowButtonVisibility: true,
    );

    expect(options.title, 'Test');
    expect(options.alwaysOnTop, isTrue);
    expect(options.skipTaskbar, isFalse);
    expect(options.windowButtonVisibility, isTrue);
  });

  testWidgets('renders its child widget', (tester) async {
    await tester.pumpWidget(_buildWrapper(child: const Text('hello')));
    expect(find.text('hello'), findsOneWidget);
  });

  group('maximize / unmaximize callbacks', () {
    testWidgets('onWindowMaximize sets isMaximized to true', (tester) async {
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowMaximize();
      expect(cubit.state.isMaximized, isTrue);
    });

    testWidgets('onWindowUnmaximize sets isMaximized back to false', (tester) async {
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowMaximize();
      listener.onWindowUnmaximize();
      expect(cubit.state.isMaximized, isFalse);
    });
  });

  group('fullscreen callbacks', () {
    testWidgets('onWindowEnterFullScreen sets isFullScreen to true', (tester) async {
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowEnterFullScreen();
      expect(cubit.state.isFullScreen, isTrue);
    });

    testWidgets('onWindowLeaveFullScreen sets isFullScreen back to false', (tester) async {
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowEnterFullScreen();
      listener.onWindowLeaveFullScreen();
      expect(cubit.state.isFullScreen, isFalse);
    });
  });

  group('resize / move / blur callbacks', () {
    testWidgets('onWindowResize saves size and position after debounce', (tester) async {
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowResize();
      await tester.pump(); // resolve getSize (getBounds)
      await tester.pump(); // resolve getPosition (getBounds)
      await tester.pump(const Duration(milliseconds: 300)); // fire debounce timers

      expect(cubit.state.windowSize, const Size(800, 600));
      expect(cubit.state.windowPosition, const Offset(100, 100));
    });

    testWidgets('onWindowMove saves position after debounce', (tester) async {
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowMove();
      await tester.pump(); // resolve getPosition (getBounds)
      await tester.pump(const Duration(milliseconds: 300)); // fire debounce timer

      expect(cubit.state.windowPosition, const Offset(100, 100));
    });

    testWidgets('onWindowBlur saves both size and position after debounce', (tester) async {
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowBlur();
      await tester.pump(); // resolve getSize (getBounds)
      await tester.pump(); // resolve getPosition (getBounds)
      await tester.pump(const Duration(milliseconds: 300)); // fire debounce timers

      expect(cubit.state.windowSize, const Size(800, 600));
      expect(cubit.state.windowPosition, const Offset(100, 100));
    });
  });

  group('_changeWindowPosition guard', () {
    testWidgets('onWindowResize saves size but skips position when maximized', (tester) async {
      setUpWindowManagerMockWith(isMaximized: true);
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowResize();
      await tester.pump(); // resolve getSize
      await tester.pump(); // resolve isMaximized + isFullScreen (guard fires)
      await tester.pump(const Duration(milliseconds: 300)); // fire size debounce

      expect(cubit.state.windowSize, const Size(800, 600));
      expect(cubit.state.windowPosition, isNull);
    });

    testWidgets('onWindowResize saves size but skips position when fullscreen', (tester) async {
      setUpWindowManagerMockWith(isFullScreen: true);
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowResize();
      await tester.pump(); // resolve getSize
      await tester.pump(); // resolve isMaximized + isFullScreen (guard fires)
      await tester.pump(const Duration(milliseconds: 300)); // fire size debounce

      expect(cubit.state.windowSize, const Size(800, 600));
      expect(cubit.state.windowPosition, isNull);
    });

    testWidgets('onWindowMove skips position when maximized', (tester) async {
      setUpWindowManagerMockWith(isMaximized: true);
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowMove();
      await tester.pump(); // resolve isMaximized + isFullScreen (guard fires)

      expect(cubit.state.windowPosition, isNull);
    });

    testWidgets('onWindowMove skips position when fullscreen', (tester) async {
      setUpWindowManagerMockWith(isFullScreen: true);
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowMove();
      await tester.pump(); // resolve isMaximized + isFullScreen (guard fires)

      expect(cubit.state.windowPosition, isNull);
    });

    testWidgets('onWindowBlur saves size but skips position when maximized', (tester) async {
      setUpWindowManagerMockWith(isMaximized: true);
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowBlur();
      await tester.pump(); // resolve getSize
      await tester.pump(); // resolve isMaximized + isFullScreen (guard fires)
      await tester.pump(const Duration(milliseconds: 300)); // fire size debounce

      expect(cubit.state.windowSize, const Size(800, 600));
      expect(cubit.state.windowPosition, isNull);
    });

    testWidgets('onWindowBlur saves size but skips position when fullscreen', (tester) async {
      setUpWindowManagerMockWith(isFullScreen: true);
      await tester.pumpWidget(_buildWrapper());
      final listener = tester.state(find.byType(PersistentWindowWrapper)) as WindowListener;

      listener.onWindowBlur();
      await tester.pump(); // resolve getSize
      await tester.pump(); // resolve isMaximized + isFullScreen (guard fires)
      await tester.pump(const Duration(milliseconds: 300)); // fire size debounce

      expect(cubit.state.windowSize, const Size(800, 600));
      expect(cubit.state.windowPosition, isNull);
    });
  });

  testWidgets('dispose removes the window listener without errors', (tester) async {
    await tester.pumpWidget(_buildWrapper());
    // Replacing the tree triggers dispose() → windowManager.removeListener(this)
    await tester.pumpWidget(const SizedBox());
  });
}
