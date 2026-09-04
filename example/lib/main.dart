import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:persistent_window_manager/persistent_window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HydratedBloc.storage must be initialised before the package is used.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(Platform.isWindows || Platform.isLinux || Platform.isMacOS
            ? Directory('${Directory.current.path}/DEBUG_STORAGE').path
            : await getTemporaryDirectory().then((dir) => dir.path)),
  );

  await runAppPersistentWindowManager(
    const _ExampleApp(),
    windowOptions: const CustomWindowOptions(
      minimumSize: Size(700, 600),
      title: 'Persistent Window Manager — Example',
    ),
    enableWindowStateLogging: true,
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
      home: Scaffold(
        appBar: AppBar(title: const Text('Persistent Window Manager')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.window, size: 64),
              SizedBox(height: 24),
              () {
                if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                  return Text(
                    'Resize or move this window, then close and reopen the app.\n'
                    'The window will reopen exactly where you left it.',
                    textAlign: TextAlign.center,
                  );
                } else {
                  return Text(
                    'This platform does not support persistent window management.\n'
                    'But it will still function normally because the wrapper will skip the wrapper on this platform.',
                    textAlign: TextAlign.center,
                  );
                }
              }(),
            ],
          ),
        ),
      ),
    );
  }
}
