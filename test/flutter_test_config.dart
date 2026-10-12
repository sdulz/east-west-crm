import 'dart:async';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        // Platform goldens differ per host font stack; CI goldens use Ahem.
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: () async {
        await testMain();
      },
    );
