# flutter_caesium_ffi

Fast, isolate-friendly image compression for Flutter, backed by
[`libcaesium` 0.20.3](https://github.com/Lymphatus/libcaesium) through a stable
C ABI and Dart FFI.

The package supports JPEG, PNG, WebP, GIF, and TIFF on Android, iOS, macOS,
Windows, and Linux. Web is not supported. Published packages include the native
libraries, so consuming applications do not need Rust or a C toolchain.

The source branch intentionally omits generated binaries. Until a pub.dev
release exists, use the complete package artifact from a successful GitHub
Actions run; a raw Git dependency is intended for contributors who rebuild the
native libraries.

> **License notice:** this package and its bundled native code are licensed
> under AGPL-3.0-or-later. Applications that distribute or provide network
> access to a modified or combined work must satisfy the AGPL and all applicable
> third-party license obligations. Review [LICENSE](LICENSE) and
> [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) before shipping.

## Requirements

- Flutter 3.22 or newer
- Dart 3.4 or newer
- Android 5.0 / API 21 or newer
- iOS 12.0 or newer
- macOS 10.14 or newer
- Linux x86_64 with glibc 2.31 or newer
- Windows x64

## Usage

```dart
import 'dart:io';
import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';

final result = await FlutterCaesiumFfi.compressFile(
  '/tmp/input.jpg',
  '/tmp/output.jpg',
  options: const CaesiumOptions(
    keepMetadata: false,
    jpeg: JpegOptions(quality: 75, progressive: true),
    resize: ResizeOptions(width: 1600),
  ),
);

print('${result.inputSize} -> ${result.outputSize} bytes');
print('native: ${FlutterCaesiumFfi.nativeVersion}');

final converted = await FlutterCaesiumFfi.convert(
  await File('/tmp/input.png').readAsBytes(),
  format: CaesiumFormat.webp,
  options: const CaesiumOptions(webp: WebpOptions(quality: 82)),
);
await File('/tmp/output.webp').writeAsBytes(converted.bytes);
```

The public operations are `compress`, `compressFile`, `compressToSize`,
`compressFileToSize`, `convert`, `convertFile`, and `nativeVersion`.

All image work runs on a background isolate. Memory input and output cross
isolate boundaries with `TransferableTypedData`.

## Options and behavior

`CaesiumOptions` exposes JPEG, PNG, WebP, GIF, TIFF, resize, and metadata
settings. Defaults match `libcaesium`: quality 80, metadata removed, progressive
JPEG enabled, and PNG optimization level 3.

File operations never overwrite an existing output. Empty input, invalid
quality or dimensions, missing input files, missing output directories, and
equal input/output paths fail before encoding starts. Native failures are
reported as `CaesiumException(code, message)`.

Target-size compression is best effort because some inputs or formats cannot
reach every requested size. Set `returnSmallest: true` to return the smallest
candidate when the exact target cannot be reached.

## Bundled platforms

| Platform | Bundled architecture |
| --- | --- |
| Android | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| iOS | arm64 device; arm64/x86_64 simulator |
| macOS | arm64/x86_64 universal |
| Windows | x64 MSVC |
| Linux | x86_64, glibc 2.31+ |

## Building native libraries

End users do not need these steps. Contributors need Rust 1.92.0 plus the
platform SDK:

```sh
dart run tool/build_native.dart --platform macos
dart run tool/build_native.dart --platform ios
dart run tool/build_native.dart --platform android
dart run tool/build_native.dart --platform linux
dart run tool/build_native.dart --platform windows
```

Android builds also require `cargo-ndk`. Regenerate private Dart bindings after
changing the C header:

```sh
dart run ffigen --config ffigen.yaml
```

Release Linux binaries use Zig to pin the glibc baseline:

```sh
FLUTTER_CAESIUM_LINUX_GLIBC=2.31 \
  dart run tool/build_native.dart --platform linux
```

GitHub Actions builds and strips each platform binary, verifies example
application linking, combines a complete package artifact, and runs
`dart pub publish --dry-run`. It does not publish to pub.dev.

## Development

```sh
flutter pub get
flutter analyze
flutter test
cargo +1.92.0 test --manifest-path rust/Cargo.toml
```

To run native integration tests against a local library:

```sh
FLUTTER_CAESIUM_FFI_LIBRARY=/absolute/path/to/libflutter_caesium_ffi.dylib \
  flutter test test/native_integration_test.dart
```

See the runnable app in [`example`](example).
