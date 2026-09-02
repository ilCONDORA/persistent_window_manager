import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';
import 'package:persistent_window_manager/src/run_app_persistent_window_manager.dart' show setupWindowManagerForTest;
import 'package:persistent_window_manager/src/widgets/persistent_window_wrapper.dart';

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
    await pumpEventQueue(); // let _init() / setPositionScaleFactor() complete
  });

  tearDown(() async {
    await cubit.close();
    clearChannelMocks();
  });

  group('setupWindowManagerForTest', () {
    test('completes successfully with null windowOptions', () async {
      await expectLater(setupWindowManagerForTest(), completes);
    });

    test('completes successfully with windowOptions', () async {
      const options = CustomWindowOptions(
        title: 'Test App',
        minimumSize: Size(400, 300),
      );
      await expectLater(setupWindowManagerForTest(windowOptions: options), completes);
    });

    test('positionScaleFactor is populated on the cubit after setup', () async {
      await setupWindowManagerForTest();
      // Mock returns scaleFactor: 1.0
      expect(cubit.state.positionScaleFactor, 1.0);
    });
  });

  group('PersistentWindowWrapper integration', () {
    // PersistentWindowWrapper is the widget runAppPersistentWindowManager passes
    // to runApp, so its behaviour is the runtime contract for the whole package.

    testWidgets('wraps and renders its child', (tester) async {
      await tester.pumpWidget(_buildWrapper(child: const Text('hello')));
      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(PersistentWindowWrapper), findsOneWidget);
    });

    testWidgets('is immediately present — no intermediate unwrapped state', (tester) async {
      await tester.pumpWidget(_buildWrapper(child: const Text('world')));
      // No future needed: the widget is in the tree from the first pump.
      expect(find.byType(PersistentWindowWrapper), findsOneWidget);
    });
  });
}
