import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';
import 'package:window_manager/window_manager.dart';

class _MockStorage extends Mock implements Storage {}

void _setUpChannelMocks() {
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

  // getSize() and getPosition() both delegate to getBounds() internally.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('window_manager'),
    (MethodCall call) async {
      if (call.method == 'getBounds') {
        return {'x': 100.0, 'y': 100.0, 'width': 800.0, 'height': 600.0};
      }
      return null;
    },
  );
}

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
  late _MockStorage storage;
  late PersistentWindowManagerCubit cubit;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    _setUpChannelMocks();

    cubit = PersistentWindowManagerCubit.instance;
    await pumpEventQueue(); // let _init() + setPositionScaleFactor() complete
  });

  tearDown(() async {
    await cubit.close();
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

  testWidgets('dispose removes the window listener without errors', (tester) async {
    await tester.pumpWidget(_buildWrapper());
    // Replacing the tree triggers dispose() → windowManager.removeListener(this)
    await tester.pumpWidget(const SizedBox());
  });
}
