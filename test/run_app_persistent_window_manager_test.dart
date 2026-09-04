import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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

  setUp(() {
    storage = MockStorage();
    initializeMockStorage(storage);
    setUpChannelMocks();
    cubit = PersistentWindowManagerCubit.instance;
  });

  tearDown(() async {
    // Drain any microtasks queued by window_manager's unawaited waitUntilReadyToShow
    // (e.g. its internal isMinimized call) before removing the channel mocks, so they
    // don't fire after clearChannelMocks() and trigger MissingPluginException.
    await pumpEventQueue(times: 30);
    await cubit.close();
    clearChannelMocks();
  });

  // Plain test() avoids the fakeAsync zone that causes testWidgets to deadlock when
  // waitUntilReadyToShow's addPostFrameCallback completer never resolves.
  test('_prepareWindow: covers ensureInitialized, setPrimaryDisplayScale, startWindowStatePolling', () async {
    await setupWindowManagerForTest();
  });

  group('PersistentWindowWrapper integration', () {
    testWidgets('wraps and renders its child', (tester) async {
      await tester.pumpWidget(_buildWrapper(child: const Text('hello')));
      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(PersistentWindowWrapper), findsOneWidget);
    });

    testWidgets('is immediately present in the widget tree', (tester) async {
      await tester.pumpWidget(_buildWrapper(child: const Text('world')));
      expect(find.byType(PersistentWindowWrapper), findsOneWidget);
    });
  });
}
