## 3.1.0

* **Architecture:** Replaced `WindowListener`-based event callbacks with a 750 ms polling loop (`Timer.periodic`). `PersistentWindowWrapper` no longer implements `WindowListener`; it uses `WidgetsBindingObserver.didChangeMetrics()` instead.
* **State simplification:** Removed `positionScaleFactor` from `PersistentWindowManagerState`; scale handling is now an internal detail of `PersistentWindowManagerCubit`.
* **Bug fix:** Fixed an issue when closing the window while minimized and then reopening it, it would restore to a broken size and position.

## 3.0.1

* Updated README.

## 3.0.0

* **BREAKING CHANGE:** Replaced `PeWiMaWrapper` with `runAppPersistentWindowManager`, a drop-in replacement for `runApp` that performs window setup _before_ Flutter renders its first frame, achieving true zero-flicker restoration.
* **BREAKING CHANGE:** Removed `PeWiMaWrapper` from the public API. Replace `runApp(PeWiMaWrapper(child, windowOptions: options))` with `await runAppPersistentWindowManager(child, windowOptions: options)`.
* **New Feature:** Added a `dart run persistent_window_manager:setup` command (`--dry-run` supported) that patches the consuming app's native desktop runner — `windows/runner/win32_window.cpp`, `windows/runner/flutter_window.cpp`, `linux/my_application.cc`, `macos/Runner/MainFlutterWindow.swift` — so the window is never shown by the OS/engine before `windowManager.show()` is called. Without this step, `runAppPersistentWindowManager`'s zero-flicker restoration only takes full effect once the runner itself also defers showing the window; see the README's "Native runner setup" section, including a manual fallback for unrecognized templates.
* **Bug fix:** `setPositionScaleFactor` is now explicitly awaited before reading window state, preventing a race condition where positions could be normalised against an uninitialised scale factor.
* **Bug fix:** `_changeWindowPosition` now skips saving position while the window is maximized or in full screen, preventing transitional off-screen coordinates from being persisted during the unmaximize animation.
* **Removed:** `PWMUtils` internal class.

## 2.0.0

* **BREAKING CHANGE:** Replaced the two-step `activatePersistentWindowManager()` + `PersistentWindowWrapper` API with the new unified `PeWiMaWrapper` widget.
* **BREAKING CHANGE:** Removed `activatePersistentWindowManager` and `PersistentWindowWrapper` from public exports. Use `PeWiMaWrapper` instead.
* **New Feature:** Introduced `PeWiMaWrapper` - a single, simplified widget that handles window manager activation and wrapping in one step.
* **Enhanced Platform Support:** Better cross-platform handling with automatic no-op on web and mobile platforms.
* **Better Code Organization:** Refactored internal structure into logical modules (`models/`, `utils/`, `widgets/`, `cubit/`).

## 1.0.1

* Made `windowOptions` parameter optional in `activatePersistentWindowManager`.

## 1.0.0

* Initial release of the `persistent_window_manager` package.
