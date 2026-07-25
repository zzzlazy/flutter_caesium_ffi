import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const String nativeAssetName =
    'src/flutter_caesium_ffi_bindings_generated.dart';
const String nativeLibraryName = 'flutter_caesium_ffi';

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

Uri resolvePrebuiltNativeAsset({
  required Uri packageRoot,
  required OS targetOS,
  required Architecture targetArchitecture,
  IOSSdk? iOSSdk,
}) {
  final String relativePath = prebuiltNativeAssetPath(
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
    iOSSdk: iOSSdk,
  );
  final Uri source = packageRoot.resolve(relativePath);
  if (!File.fromUri(source).existsSync()) {
    throw StateError(
      'Missing prebuilt Native Asset for ${targetOS.name}/'
      '${targetArchitecture.name}'
      '${iOSSdk == null ? '' : '/${iOSSdk.type}'}: '
      '${source.toFilePath()}',
    );
  }
  return source;
}

String prebuiltNativeAssetPath({
  required OS targetOS,
  required Architecture targetArchitecture,
  IOSSdk? iOSSdk,
}) {
  final String? path = switch ((targetOS, targetArchitecture, iOSSdk)) {
    (OS.android, Architecture.arm, _) =>
      'native/android/armeabi-v7a/libflutter_caesium_ffi.so',
    (OS.android, Architecture.arm64, _) =>
      'native/android/arm64-v8a/libflutter_caesium_ffi.so',
    (OS.android, Architecture.x64, _) =>
      'native/android/x86_64/libflutter_caesium_ffi.so',
    (OS.iOS, Architecture.arm64, IOSSdk.iPhoneOS) =>
      'native/ios/arm64/libflutter_caesium_ffi.dylib',
    (OS.iOS, Architecture.arm64, IOSSdk.iPhoneSimulator) =>
      'native/ios/arm64-simulator/libflutter_caesium_ffi.dylib',
    (OS.iOS, Architecture.x64, IOSSdk.iPhoneSimulator) =>
      'native/ios/x64-simulator/libflutter_caesium_ffi.dylib',
    (OS.macOS, Architecture.arm64, _) =>
      'native/macos/arm64/libflutter_caesium_ffi.dylib',
    (OS.macOS, Architecture.x64, _) =>
      'native/macos/x64/libflutter_caesium_ffi.dylib',
    (OS.linux, Architecture.x64, _) =>
      'native/linux/x64/libflutter_caesium_ffi.so',
    (OS.windows, Architecture.x64, _) =>
      'native/windows/x64/flutter_caesium_ffi.dll',
    _ => null,
  };
  if (path == null) {
    throw UnsupportedError(
      'flutter_caesium_ffi does not provide a prebuilt Native Asset for '
      '${targetOS.name}/${targetArchitecture.name}'
      '${iOSSdk == null ? '' : '/${iOSSdk.type}'}.',
    );
  }
  return path;
}
