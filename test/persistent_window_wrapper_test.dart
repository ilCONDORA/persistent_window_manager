import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/src/cubit/pwm_cubit.dart';
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
    await cubit.close();
    clearChannelMocks();
  });

  testWidgets('renders its child widget', (tester) async {
    await tester.pumpWidget(_buildWrapper(child: const Text('hello')));
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('didChangeMetrics syncs DPR to the cubit without error', (tester) async {
    await tester.pumpWidget(_buildWrapper());
    final observer = tester.state(find.byType(PersistentWindowWrapper)) as WidgetsBindingObserver;
    // Directly invoke the observer callback, as WidgetsBinding would on a real metrics change.
    observer.didChangeMetrics();
    await tester.pump();
  });

  testWidgets('dispose removes the observer without errors', (tester) async {
    await tester.pumpWidget(_buildWrapper());
    await tester.pumpWidget(const SizedBox()); // triggers dispose()
  });
}
