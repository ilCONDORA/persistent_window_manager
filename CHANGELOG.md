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
