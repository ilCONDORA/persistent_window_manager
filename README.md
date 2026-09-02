# persistent_window_manager

[![pub package](https://img.shields.io/pub/v/persistent_window_manager.svg)](https://pub.dev/packages/persistent_window_manager)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Saves and restores a Flutter desktop window's position, size, maximized, and full-screen state between sessions.

Built on top of [`window_manager`](https://pub.dev/packages/window_manager), [`screen_retriever`](https://pub.dev/packages/screen_retriever), and [`hydrated_bloc`](https://pub.dev/packages/hydrated_bloc).

## Features

- **Zero-flicker restoration:** Restores the last saved size, position, and window state before displaying the window on startup — once the one-time native setup below is applied (without it, the OS/engine may briefly show the window with default geometry first; see [Native runner setup](#native-runner-setup)).
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
  persistent_window_manager: ^3.0.0
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

### 3. Replace `runApp`

Replace `runApp` with `runAppPersistentWindowManager` — it performs window setup *before* Flutter renders its first frame, then calls `runApp` for you:

```dart
import 'package:flutter/material.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... HydratedBloc.storage initialization ...

  await runAppPersistentWindowManager(
    const MyApp(),
    windowOptions: const CustomWindowOptions(
      minimumSize: Size(700, 600),
      title: 'My App',
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

**Note:** `runAppPersistentWindowManager` automatically handles platform detection. On web and mobile platforms, it simply calls `runApp` without any window management. This allows you to write a unified `main()` function that works across all targets.

See `example/lib/main.dart` for a complete runnable implementation.

### 4. Native runner setup <a id="native-runner-setup"></a>

This step is what makes restoration truly flicker-free. `window_manager` (and therefore this package) only controls window visibility through its own `show()`/`hide()` calls — it has no say over the fact that the default Flutter desktop runner shows the window *on its own* as soon as it's ready, independently of and often before your saved position/size/maximized state has been applied. Without this step you may briefly see the window appear at a default position and then jump to its restored geometry.

Run once, from the root of your **app**:

```
dart run persistent_window_manager:setup
```

Add `--dry-run` to preview the changes without writing anything:

```
dart run persistent_window_manager:setup --dry-run
```

This patches, when present:

- `windows/runner/win32_window.cpp` — removes `WS_VISIBLE` from window creation, if present.
- `windows/runner/flutter_window.cpp` — disables the automatic `this->Show()` call inside `SetNextFrameCallback`.
- `linux/my_application.cc` — disables/replaces the automatic show (handles both the legacy and the current GTK template).
- `macos/Runner/MainFlutterWindow.swift` — adds an `order(_:relativeTo:)` override calling `window_manager`'s `hiddenWindowAtLaunch()`.
The command is safe to re-run: every change is idempotent, and any file whose content doesn't exactly match a known template is left untouched and reported instead, so you can apply it by hand. Review `git diff` afterwards before committing, as with any generated change to native project files.

<details>
<summary>Manual setup (if the script reports a file as unrecognized)</summary>
**`windows/runner/win32_window.cpp`** — in the `CreateWindow` call, remove `| WS_VISIBLE`:
 
```diff
- window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
+ window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
```
 
**`windows/runner/flutter_window.cpp`** — remove the `this->Show();` call inside `SetNextFrameCallback` (leave `ForceRedraw()`, if present, untouched):
 
```diff
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
-   this->Show();
  });
```
 
**`linux/my_application.cc`** — depending on your Flutter SDK version, you'll have one of two variants. Modern templates connect the show to the view's `first-frame` signal:
 
```diff
  static void first_frame_cb(MyApplication* self, FlView* view) {
-   gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
  }
```
 
Older templates show the window immediately after creation:
 
```diff
  gtk_window_set_default_size(window, width, height);
- gtk_widget_show(GTK_WIDGET(window));
+ gtk_widget_realize(GTK_WIDGET(window));
```
 
**`macos/Runner/MainFlutterWindow.swift`** — add the import and override:
 
```diff
  import Cocoa
  import FlutterMacOS
+ import window_manager
 
  class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
      // ...
      super.awakeFromNib()
    }
 
+   override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
+     super.order(place, relativeTo: otherWin)
+     hiddenWindowAtLaunch()
+   }
  }
```
 
</details>

## Support & Contributions

If this package saved you time or made your Flutter desktop development smoother, consider supporting its development! 

[![Buy Me a Tea](https://img.shields.io/badge/Buy%20Me%20a%20Tea-ff5e5b?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/ilcondora)

*(And let's be honest, tea is far superior to coffee anyway 🫖)*

