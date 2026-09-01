# persistent_window_manager

[![pub package](https://img.shields.io/pub/v/persistent_window_manager.svg)](https://pub.dev/packages/persistent_window_manager)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Saves and restores a Flutter desktop window's position, size, maximized, and full-screen state between sessions.

Built on top of [`window_manager`](https://pub.dev/packages/window_manager), [`screen_retriever`](https://pub.dev/packages/screen_retriever), and [`hydrated_bloc`](https://pub.dev/packages/hydrated_bloc).

## Features

- **Zero-flicker restoration:** Restores the last saved size, position, and window state before displaying the window on startup.
- **Smart debouncing:** Listens to window events and persists position/size changes without impacting UI performance during live resizing.
- **Off-screen prevention:** Ensures windows aren't restored outside visible bounds if monitor setups change.
- **Cross-platform safety:** Automatically no-ops on web and mobile platforms, keeping your `main()` unified across all targets.

## Supported Platforms

- Windows
- macOS
- Linux

## Setup

### 1. Add dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  persistent_window_manager: ^2.0.0
```

### 2. Initialize `HydratedBloc.storage`

`HydratedBloc.storage` must be initialized before the package is used. Keeping this explicit ensures your app retains full control over storage directory logic:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getApplicationSupportDirectory()).path),
  );

  // ...
}
```

### 3. Wrap Your App

Wrap your root widget with `PeWiMaWrapper` to enable persistent window management:

```dart
import 'package:flutter/material.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... HydratedBloc.storage initialization ...

  runApp(
    PeWiMaWrapper(
      const MyApp(),
      windowOptions: const CustomWindowOptions(
        minimumSize: Size(700, 600),
        title: 'My App',
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Hello World')),
      ),
    );
  }
}
```

**Note:** `PeWiMaWrapper` automatically handles platform detection. On web and mobile platforms, it simply renders the child widget without window management. This allows you to write a unified `main()` function that works across all targets.

See `example/lib/main.dart` for a complete runnable implementation.

## Support & Contributions

If this package saved you time or made your Flutter desktop development smoother, consider supporting its development! 

[![Buy Me a Tea](https://img.shields.io/badge/Buy%20Me%20a%20Tea-ff5e5b?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/ilcondora)

*(And let's be honest, tea is far superior to coffee anyway 🫖)*

