import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_window_manager/src/models/custom_window_options.dart';
import 'package:persistent_window_manager/src/pe_wi_ma_wrapper.dart';
import 'package:persistent_window_manager/src/widgets/persistent_window_wrapper.dart';

import 'test_utils.dart';

Widget _buildTestApp({Widget child = const SizedBox()}) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  late MockStorage storage;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    storage = MockStorage();
    initializeMockStorage(storage);
    setUpChannelMocks();
  });

  tearDown(() {
    clearChannelMocks();
  });

  group('PeWiMaWrapper', () {
    testWidgets('renders child without PersistentWindowWrapper while future is loading', (ester) async {
      const testChild = Text('Test Child');
      await ester.pumpWidget(
        _buildTestApp(
          child: const PeWiMaWrapper(
            testChild,
            windowOptions: CustomWindowOptions(title: 'Test'),
          ),
        ),
      );

      // Initially, child should be rendered without wrap
      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(PersistentWindowWrapper), findsNothing);
    });

    testWidgets('wraps child with PersistentWindowWrapper when activation succeeds', (tester) async {
      const testChild = Text('Test Child');
      await tester.pumpWidget(
        _buildTestApp(
          child: const PeWiMaWrapper(
            testChild,
            windowOptions: CustomWindowOptions(title: 'Test'),
          ),
        ),
      );

      // Initial state: child without wrap
      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(PersistentWindowWrapper), findsNothing);

      // Wait for the future to complete
      await tester.pumpAndSettle();

      // After future completes, child should be wrapped
      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(PersistentWindowWrapper), findsOneWidget);
    });

    testWidgets('renders child without PersistentWindowWrapper when activation fails', (tester) async {
      // Clear mocks to make activation fail
      clearChannelMocks();

      const testChild = Text('Test Child');
      await tester.pumpWidget(
        _buildTestApp(
          child: const PeWiMaWrapper(
            testChild,
            windowOptions: CustomWindowOptions(title: 'Test'),
          ),
        ),
      );

      // Wait for the future to complete
      await tester.pumpAndSettle();

      // Child should be rendered without wrap when activation fails
      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(PersistentWindowWrapper), findsNothing);

      // Re-setup mocks for other tests
      setUpChannelMocks();
    });

    testWidgets('accepts null windowOptions', (tester) async {
      const testChild = Text('Test Child');
      await tester.pumpWidget(
        _buildTestApp(
          child: const PeWiMaWrapper(testChild),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);

      await tester.pumpAndSettle();

      // Should still wrap the child when activation succeeds
      expect(find.byType(PersistentWindowWrapper), findsOneWidget);
    });

    testWidgets('preserves child widget properties after wrapping', (tester) async {
      const testChild = Text('Test Child', key: Key('child-key'));
      await tester.pumpWidget(
        _buildTestApp(
          child: const PeWiMaWrapper(
            testChild,
            windowOptions: CustomWindowOptions(title: 'Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Child widget should still be present with its key
      expect(find.byKey(const Key('child-key')), findsOneWidget);
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('can be recreated with different windowOptions', (tester) async {
      const testChild = Text('Test Child');
      await tester.pumpWidget(
        _buildTestApp(
          child: const PeWiMaWrapper(
            testChild,
            windowOptions: CustomWindowOptions(title: 'Test 1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PersistentWindowWrapper), findsOneWidget);

      // Update with different windowOptions
      await tester.pumpWidget(
        _buildTestApp(
          child: const PeWiMaWrapper(
            testChild,
            windowOptions: CustomWindowOptions(title: 'Test 2'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still be wrapped
      expect(find.byType(PersistentWindowWrapper), findsOneWidget);
    });
  });
}
