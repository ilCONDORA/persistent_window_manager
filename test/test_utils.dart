import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

/// Sets up mock method handlers for screen_retriever and window_manager channels.
/// Includes visiblePosition and visibleSize for proper window centering.
void setUpChannelMocks() {
  // Mock screen_retriever for display information
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('dev.leanflutter.plugins/screen_retriever'),
    (MethodCall call) async {
      if (call.method == 'getPrimaryDisplay') {
        return {
          'id': '1',
          'name': 'Test Display',
          'size': {'width': 1920.0, 'height': 1080.0},
          'scaleFactor': 1.0,
          'visiblePosition': {'dx': 0.0, 'dy': 0.0},
          'visibleSize': {'width': 1920.0, 'height': 1080.0},
        };
      }
      if (call.method == 'getDisplays') {
        return [
          {
            'id': '1',
            'name': 'Test Display',
            'size': {'width': 1920.0, 'height': 1080.0},
            'scaleFactor': 1.0,
            'visiblePosition': {'dx': 0.0, 'dy': 0.0},
            'visibleSize': {'width': 1920.0, 'height': 1080.0},
          },
        ];
      }
      return null;
    },
  );

  // Mock window_manager for window operations
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('window_manager'),
    (MethodCall call) async {
      if (call.method == 'getBounds') {
        return {'x': 100.0, 'y': 100.0, 'width': 800.0, 'height': 600.0};
      }
      if (call.method == 'isMaximized') {
        return false;
      }
      if (call.method == 'isDocked') {
        return false;
      }
      if (call.method == 'isMinimized') {
        return false;
      }
      if (call.method == 'isFullScreen') {
        return false;
      }
      if (call.method == 'isVisibleOnAllWorkspaces') {
        return false;
      }
      return null;
    },
  );
}

/// Re-registers only the window_manager mock with configurable [isMaximized] and [isFullScreen]
/// values, overriding the defaults set by [setUpChannelMocks]. Useful for testing guards that
/// depend on window state.
void setUpWindowManagerMockWith({bool isMaximized = false, bool isFullScreen = false}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('window_manager'),
    (MethodCall call) async {
      if (call.method == 'getBounds') {
        return {'x': 100.0, 'y': 100.0, 'width': 800.0, 'height': 600.0};
      }
      if (call.method == 'isMaximized') return isMaximized;
      if (call.method == 'isDocked') return false;
      if (call.method == 'isMinimized') return false;
      if (call.method == 'isFullScreen') return isFullScreen;
      if (call.method == 'isVisibleOnAllWorkspaces') return false;
      return null;
    },
  );
}

/// Clears mock method handlers for screen_retriever and window_manager channels.
void clearChannelMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('dev.leanflutter.plugins/screen_retriever'),
    null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('window_manager'),
    null,
  );
}

/// Initializes mock storage with default behavior.
/// All read operations return null, all write/delete/clear operations complete successfully.
void initializeMockStorage(MockStorage storage) {
  when(() => storage.read(any())).thenReturn(null);
  when(() => storage.write(any(), any())).thenAnswer((_) async {});
  when(() => storage.delete(any())).thenAnswer((_) async {});
  when(() => storage.clear()).thenAnswer((_) async {});
  HydratedBloc.storage = storage;
}
