import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks/hooks.dart';

import '../hook/build.dart' as build_hook;

void main() {
  final Uri packageRoot = Directory.current.uri;

  test('maps every supported Native Asset to a bundled file', () {
    final List<
      ({OS os, Architecture architecture, IOSSdk? iOSSdk, String path})
    >
    cases = <({OS os, Architecture architecture, IOSSdk? iOSSdk, String path})>[
      (
        os: OS.android,
        architecture: Architecture.arm,
        iOSSdk: null,
        path: 'native/android/armeabi-v7a/libflutter_caesium_ffi.so',
      ),
      (
        os: OS.android,
        architecture: Architecture.arm64,
        iOSSdk: null,
        path: 'native/android/arm64-v8a/libflutter_caesium_ffi.so',
      ),
      (
        os: OS.android,
        architecture: Architecture.x64,
        iOSSdk: null,
        path: 'native/android/x86_64/libflutter_caesium_ffi.so',
      ),
      (
        os: OS.iOS,
        architecture: Architecture.arm64,
        iOSSdk: IOSSdk.iPhoneOS,
        path: 'native/ios/arm64/libflutter_caesium_ffi.dylib',
      ),
      (
        os: OS.iOS,
        architecture: Architecture.arm64,
        iOSSdk: IOSSdk.iPhoneSimulator,
        path: 'native/ios/arm64-simulator/libflutter_caesium_ffi.dylib',
      ),
      (
        os: OS.iOS,
        architecture: Architecture.x64,
        iOSSdk: IOSSdk.iPhoneSimulator,
        path: 'native/ios/x64-simulator/libflutter_caesium_ffi.dylib',
      ),
      (
        os: OS.macOS,
        architecture: Architecture.arm64,
        iOSSdk: null,
        path: 'native/macos/arm64/libflutter_caesium_ffi.dylib',
      ),
      (
        os: OS.macOS,
        architecture: Architecture.x64,
        iOSSdk: null,
        path: 'native/macos/x64/libflutter_caesium_ffi.dylib',
      ),
      (
        os: OS.linux,
        architecture: Architecture.x64,
        iOSSdk: null,
        path: 'native/linux/x64/libflutter_caesium_ffi.so',
      ),
      (
        os: OS.windows,
        architecture: Architecture.x64,
        iOSSdk: null,
        path: 'native/windows/x64/flutter_caesium_ffi.dll',
      ),
    ];

    for (final entry in cases) {
      expect(
        build_hook.prebuiltNativeAssetPath(
          targetOS: entry.os,
          targetArchitecture: entry.architecture,
          iOSSdk: entry.iOSSdk,
        ),
        entry.path,
      );
      expect(
        File.fromUri(
          build_hook.resolvePrebuiltNativeAsset(
            packageRoot: packageRoot,
            targetOS: entry.os,
            targetArchitecture: entry.architecture,
            iOSSdk: entry.iOSSdk,
          ),
        ).existsSync(),
        isTrue,
        reason: entry.path,
      );
    }
  });

  test('rejects unsupported targets', () {
    expect(
      () => build_hook.prebuiltNativeAssetPath(
        targetOS: OS.linux,
        targetArchitecture: Architecture.arm64,
      ),
      throwsUnsupportedError,
    );
    expect(
      () => build_hook.prebuiltNativeAssetPath(
        targetOS: OS.iOS,
        targetArchitecture: Architecture.x64,
        iOSSdk: IOSSdk.iPhoneOS,
      ),
      throwsUnsupportedError,
    );
  });

  test('reports a missing selected prebuilt', () {
    expect(
      () => build_hook.resolvePrebuiltNativeAsset(
        packageRoot: Uri.directory(
          '${Directory.systemTemp.path}/flutter_caesium_ffi_missing/',
        ),
        targetOS: OS.linux,
        targetArchitecture: Architecture.x64,
      ),
      throwsA(
        isA<StateError>().having(
          (StateError error) => error.message,
          'message',
          contains('Missing prebuilt Native Asset'),
        ),
      ),
    );
  });

  test('build hook bundles the selected library with the fixed asset ID', () {
    return testCodeBuildHook(
      mainMethod: build_hook.main,
      targetOS: OS.macOS,
      targetArchitecture: Architecture.arm64,
      check: (BuildInput input, BuildOutput output) {
        final CodeAsset asset = CodeAsset.fromEncoded(
          output.assets.encodedAssets.single,
        );
        expect(
          asset.id,
          'package:flutter_caesium_ffi/'
          'src/flutter_caesium_ffi_bindings_generated.dart',
        );
        expect(asset.linkMode, isA<DynamicLoadingBundled>());
        expect(asset.file?.pathSegments.last, 'libflutter_caesium_ffi.dylib');
        expect(File.fromUri(asset.file!).existsSync(), isTrue);
      },
    );
  });

  test('build hook emits no assets when code assets are disabled for Web', () {
    return testBuildHook(
      mainMethod: build_hook.main,
      extensions: const <ProtocolExtension>[],
      check: (BuildInput input, BuildOutput output) {
        expect(output.assets.encodedAssets, isEmpty);
      },
    );
  });
}
