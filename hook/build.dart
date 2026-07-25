import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

import 'src/native_asset.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final CodeConfig config = input.config.code;
    final Uri source = resolvePrebuiltNativeAsset(
      packageRoot: input.packageRoot,
      targetOS: config.targetOS,
      targetArchitecture: config.targetArchitecture,
      iOSSdk: config.targetOS == OS.iOS ? config.iOS.targetSdk : null,
    );
    final Uri destination = input.outputDirectory.resolve(
      config.targetOS.dylibFileName(nativeLibraryName),
    );

    await File.fromUri(source).copy(destination.toFilePath());
    output.dependencies.add(source);
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: nativeAssetName,
        linkMode: DynamicLoadingBundled(),
        file: destination,
      ),
    );
  });
}
