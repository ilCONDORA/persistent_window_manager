# persistent_window_manager

[![pub package](https://img.shields.io/pub/v/persistent_window_manager.svg)](https://pub.dev/packages/persistent_window_manager)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Saves and restores a Flutter desktop window's position, size, maximized, and full-screen state between sessions.

Built on top of [`window_manager`](https://pub.dev/packages/window_manager), [`screen_retriever`](https://pub.dev/packages/screen_retriever), and [`hydrated_bloc`](https://pub.dev/packages/hydrated_bloc).

## Features

- **Zero-flicker restoration:** Restores the last saved size, position, and window state before displaying the window on startup.
- **Smart debouncing:** Listens to window events and persists position/size changes without impacting UI performance during live resizing.
- **Off-screen prevention:** Ensures windows aren't restored outside visible bounds if monitor setups change.
- **Cross-platform safety:** Automatically no-ops on web and mobile (`activatePersistentWindowManager` returns `false`), keeping your `main()` unified across all targets.

## Supported Platforms

- Windows
- macOS
- Linux

## Setup

### 1. Add dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  persistent_window_manager: ^1.0.0
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

### 3. Activate and Wrap

Call `activatePersistentWindowManager` and if needed, customize the window options, then wrap your root widget in `PersistentWindowWrapper`:

```dart
import 'package:flutter/material.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';

void main() async {
  // ... HydratedStorage initialization

  final bool useWindowManager = await activatePersistentWindowManager(
    windowOptions: const CustomWindowOptions(
      minimumSize: Size(700, 600),
    ),
  );

  runApp(
    useWindowManager
        ? PersistentWindowWrapper(child: const MyApp())
        : const MyApp(),
  );
}
```

See `example/lib/main.dart` for a complete runnable implementation.

## Support & Contributions

If this package saved you time or made your Flutter desktop development smoother, consider supporting its development! 

[![Buy Me a Tea](https://img.shields.io/badge/Buy%20Me%20a%20Tea-ff5e5b?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/ilcondora)

*(And let's be honest, tea is far superior to coffee anyway 🫖)*

