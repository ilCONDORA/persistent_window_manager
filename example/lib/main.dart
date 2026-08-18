import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:persistent_window_manager/persistent_window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HydratedBloc.storage must be initialised before the package is used.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(Directory('${Directory.current.path}/DEBUG_STORAGE').path),
  );

  // Activate the window manager; returns false on web / mobile so the same
  // main() works across all targets without any platform checks at the call site.
  final bool useWindowManager = await activatePersistentWindowManager(
    windowOptions: const CustomWindowOptions(
      minimumSize: Size(700, 600),
      title: 'Persistent Window Manager — Example',
    ),
  );

  runApp(
    useWindowManager ? PersistentWindowWrapper(child: const _ExampleApp()) : const _ExampleApp(),
  );
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persistent Window Manager — Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persistent Window Manager')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.window, size: 64),
            SizedBox(height: 24),
            Text(
              'Resize or move this window, then close and reopen the app.\n'
              'The window will reopen exactly where you left it.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
